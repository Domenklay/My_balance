"""MyBalance community API v1. Deploy behind HTTPS using a WSGI server."""
import hashlib, json, math, os, re, secrets, sqlite3, time
from urllib.parse import parse_qs
from contextlib import closing

DB = os.environ.get("MYBALANCE_DB", "community.sqlite3")
CATEGORIES = {"other","soups","mains","salads","breakfast","desserts","snacks","baking","drinks","sauces"}
MAX_BODY = 128000

def db():
    conn = sqlite3.connect(DB, timeout=10)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys=ON")
    conn.execute("PRAGMA journal_mode=WAL")
    conn.executescript("""
    CREATE TABLE IF NOT EXISTS accounts(id TEXT PRIMARY KEY, token TEXT UNIQUE NOT NULL, created INTEGER NOT NULL);
    CREATE TABLE IF NOT EXISTS recipes(id TEXT PRIMARY KEY, owner TEXT NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
      content TEXT NOT NULL, kcal INTEGER NOT NULL, status TEXT NOT NULL DEFAULT 'pending', created INTEGER NOT NULL);
    CREATE TABLE IF NOT EXISTS ratings(recipe TEXT REFERENCES recipes(id) ON DELETE CASCADE, account TEXT REFERENCES accounts(id) ON DELETE CASCADE,
      score INTEGER NOT NULL CHECK(score BETWEEN 1 AND 5), PRIMARY KEY(recipe,account));
    CREATE TABLE IF NOT EXISTS reports(recipe TEXT REFERENCES recipes(id) ON DELETE CASCADE, account TEXT REFERENCES accounts(id) ON DELETE CASCADE,
      reason TEXT NOT NULL, PRIMARY KEY(recipe,account));
    CREATE TABLE IF NOT EXISTS limits(key TEXT PRIMARY KEY, count INTEGER NOT NULL, expires INTEGER NOT NULL);
    CREATE INDEX IF NOT EXISTS recipe_status ON recipes(status,created);
    """)
    return conn

class APIError(Exception):
    def __init__(self, status, message): self.status, self.message = status, message

def bounded_text(x, limit, required=True):
    if not isinstance(x,str) or len(x)>limit or (required and not x.strip()):
        raise APIError(400,"invalid_text")
    return x.strip()

def number(x, lo, hi):
    if type(x) not in (int,float) or not math.isfinite(x) or not lo<=x<=hi:
        raise APIError(400,"invalid_number")
    return x

def clean_recipe(x):
    if not isinstance(x,dict): raise APIError(400,"invalid_recipe")
    name=bounded_text(x.get("name"),160)
    category=x.get("category","other")
    if not isinstance(category,str) or category not in CATEGORIES: raise APIError(400,"invalid_category")
    instructions=bounded_text(x.get("instructions",""),8000,False)
    weight=number(x.get("cooked_weight"),1,50000)
    servings=number(x.get("servings"),1,100)
    parts=x.get("ingredients")
    if not isinstance(parts,list) or not 1<=len(parts)<=40: raise APIError(400,"invalid_ingredients")
    result=[]; total=0.0
    for item in parts:
        if not isinstance(item,dict): raise APIError(400,"invalid_ingredient")
        unit=item.get("unit","г")
        if unit not in ("г","мл"): raise APIError(400,"invalid_unit")
        part={"name":bounded_text(item.get("name"),160),"unit":unit,"grams":number(item.get("grams"),0.001,10000)}
        for key in ("kcal","p","f","c"): part[key]=number(item.get(key),0,1000 if key=="kcal" else 100)
        total+=part["kcal"]*part["grams"]/100
        result.append(part)
    return {"name":name,"category":category,"instructions":instructions,"cooked_weight":weight,"servings":servings,"ingredients":result}, math.floor(total/servings+0.5)

def read_json(env):
    try:
        size=int(env.get("CONTENT_LENGTH") or 0)
        if not 0<size<=MAX_BODY: raise APIError(413,"invalid_size")
        data=json.loads(env["wsgi.input"].read(size))
    except (ValueError,UnicodeError): raise APIError(400,"invalid_json")
    if not isinstance(data,dict): raise APIError(400,"invalid_json")
    return data

def digest(token): return hashlib.sha256(token.encode()).hexdigest()

def account(conn,env):
    header=env.get("HTTP_AUTHORIZATION","")
    if not re.fullmatch(r"Bearer [a-f0-9]{64}",header): raise APIError(401,"authentication_required")
    row=conn.execute("SELECT id FROM accounts WHERE token=?",(digest(header[7:]),)).fetchone()
    if not row: raise APIError(401,"authentication_required")
    return row["id"]

def limit(conn,key,count,window):
    now=int(time.time())
    conn.execute("DELETE FROM limits WHERE expires<=?",(now,))
    conn.execute("INSERT INTO limits VALUES(?,1,?) ON CONFLICT(key) DO UPDATE SET count=count+1",(key,now+window))
    n=conn.execute("SELECT count FROM limits WHERE key=?",(key,)).fetchone()[0]
    if n>count: raise APIError(429,"rate_limit")

def visible(conn, rid):
    row=conn.execute("SELECT * FROM recipes WHERE id=? AND status='approved'",(rid,)).fetchone()
    if not row: raise APIError(404,"recipe_not_found")
    return row

def serialize(row):
    return {"id":row["id"],"recipe":json.loads(row["content"]),"kcal":row["kcal"],"status":row["status"],
            "rating":round(row["average"] or 0,1),"votes":row["votes"]}

def dispatch(conn,env):
    method,path=env["REQUEST_METHOD"],env["PATH_INFO"]
    if method=="GET" and path=="/v1/health": return {"version":1}
    if method=="POST" and path=="/v1/accounts":
        limit(conn,"register:"+digest(env.get("REMOTE_ADDR","unknown")),10,3600)
        token=secrets.token_hex(32); uid=secrets.token_hex(16)
        conn.execute("INSERT INTO accounts VALUES(?,?,?)",(uid,digest(token),int(time.time())))
        return {"token":token}
    if method=="GET" and path in ("/v1/recipes","/v1/mine"):
        query=parse_qs(env.get("QUERY_STRING",""))
        clauses=[]; args=[]
        if path.endswith("mine"): clauses.append("r.owner=?"); args.append(account(conn,env))
        else: clauses.append("r.status='approved'")
        category=query.get("category",[""])[0]
        if category in CATEGORIES: clauses.append("json_extract(r.content,'$.category')=?"); args.append(category)
        try: ceiling=int(query.get("max_kcal",["0"])[0]); offset=max(0,min(10000,int(query.get("offset",["0"])[0])))
        except ValueError: raise APIError(400,"invalid_filter")
        if ceiling in (200,350,500,750): clauses.append("r.kcal<=?"); args.append(ceiling)
        elif ceiling==-1: clauses.append("r.kcal>750")
        needle=query.get("q",[""])[0].strip().casefold()[:100]
        conn.create_function("casefold",1,lambda v: v.casefold())
        if needle: clauses.append("instr(casefold(r.content),?)>0"); args.append(needle)
        order="average DESC,votes DESC,r.created DESC" if query.get("sort",[""])[0]=="rating" else "r.created DESC,r.id DESC"
        rows=conn.execute("SELECT r.*, (SELECT AVG(score) FROM ratings WHERE recipe=r.id) average, (SELECT COUNT(*) FROM ratings WHERE recipe=r.id) votes FROM recipes r WHERE "+" AND ".join(clauses)+" ORDER BY "+order+" LIMIT 21 OFFSET ?",[*args,offset]).fetchall()
        return {"items":[serialize(row) for row in rows[:20]],"more":len(rows)>20}
    uid=account(conn,env)
    limit(conn,"write:"+uid,60,3600)
    if method=="POST" and path=="/v1/recipes":
        data=read_json(env)
        if data.get("consent") is not True: raise APIError(400,"consent_required")
        recipe,kcal=clean_recipe(data.get("recipe"))
        if conn.execute("SELECT count(*) FROM recipes WHERE owner=?",(uid,)).fetchone()[0]>=100: raise APIError(429,"recipe_limit")
        rid=secrets.token_hex(16)
        conn.execute("INSERT INTO recipes VALUES(?,?,?,?,?,?)",(rid,uid,json.dumps(recipe,ensure_ascii=False),kcal,"pending",int(time.time())))
        return {"id":rid,"status":"pending"}
    if method=="DELETE" and path=="/v1/account":
        conn.execute("DELETE FROM accounts WHERE id=?",(uid,))
        return {"deleted":True}
    match=re.fullmatch(r"/v1/recipes/([a-f0-9]{32})(?:/(rating|report))?",path)
    if match:
        rid,action=match.groups()
        if method=="DELETE" and action is None:
            if not conn.execute("DELETE FROM recipes WHERE id=? AND owner=?",(rid,uid)).rowcount: raise APIError(404,"recipe_not_found")
            return {"deleted":True}
        if method=="POST" and action:
            row=visible(conn,rid); data=read_json(env)
            if action=="rating":
                score=data.get("score")
                if type(score) is not int or not 1<=score<=5 or row["owner"]==uid: raise APIError(400,"invalid_rating")
                conn.execute("INSERT INTO ratings VALUES(?,?,?) ON CONFLICT(recipe,account) DO UPDATE SET score=excluded.score",(rid,uid,score))
            else:
                reason=bounded_text(data.get("reason"),500)
                conn.execute("INSERT INTO reports VALUES(?,?,?) ON CONFLICT(recipe,account) DO UPDATE SET reason=excluded.reason",(rid,uid,reason))
            return {"saved":True}
    raise APIError(404,"not_found")

def application(env,start_response):
    try:
        with closing(db()) as conn:
            with conn:
                result=dispatch(conn,env)
        status="200 OK"
    except APIError as e:
        status={400:"400 Bad Request",401:"401 Unauthorized",404:"404 Not Found",413:"413 Payload Too Large",429:"429 Too Many Requests"}[e.status]
        result={"error":e.message}
    except Exception:
        status="500 Internal Server Error"; result={"error":"server_error"}
    body=json.dumps(result,ensure_ascii=False,allow_nan=False).encode()
    start_response(status,[("Content-Type","application/json; charset=utf-8"),("Content-Length",str(len(body))),("Cache-Control","no-store"),("X-Content-Type-Options","nosniff")])
    return [body]

if __name__=="__main__":
    import argparse
    parser=argparse.ArgumentParser()
    parser.add_argument("action",choices=["queue","approve","reject","hide","serve"])
    parser.add_argument("id",nargs="?")
    args=parser.parse_args()
    if args.action=="serve":
        from wsgiref.simple_server import make_server
        with make_server("127.0.0.1",8000,application) as http: http.serve_forever()
    else:
        with closing(db()) as conn, conn:
            if args.action=="queue":
                for row in conn.execute("SELECT r.id,r.status,r.content,(SELECT count(*) FROM reports WHERE recipe=r.id) reports FROM recipes r WHERE r.status='pending' OR EXISTS(SELECT 1 FROM reports WHERE recipe=r.id)"):
                    print(json.dumps(dict(row),ensure_ascii=False))
                for row in conn.execute("SELECT recipe,reason FROM reports"): print(json.dumps(dict(row),ensure_ascii=False))
            else:
                if not args.id or not re.fullmatch("[a-f0-9]{32}",args.id): parser.error("recipe id required")
                status={"approve":"approved","reject":"rejected","hide":"hidden"}[args.action]
                if not conn.execute("UPDATE recipes SET status=? WHERE id=?",(status,args.id)).rowcount: parser.error("unknown recipe")
                conn.execute("DELETE FROM reports WHERE recipe=?",(args.id,))
