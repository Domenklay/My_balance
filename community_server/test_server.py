import io, json, tempfile, unittest
from pathlib import Path
import server

class CommunityTest(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory()
        server.DB=str(Path(self.temp.name)/"db.sqlite")
    def tearDown(self): self.temp.cleanup()
    def call(self, method, path, data=None, token="", query=""):
        raw=json.dumps(data or {}).encode()
        env={"REQUEST_METHOD":method,"PATH_INFO":path,"QUERY_STRING":query,"CONTENT_LENGTH":str(len(raw)),"wsgi.input":io.BytesIO(raw),"REMOTE_ADDR":"test","HTTP_AUTHORIZATION":"Bearer "+token}
        codes=[]
        body=b"".join(server.application(env,lambda status,headers:codes.append(int(status[:3]))))
        return codes[0],json.loads(body)
    def test_flow(self):
        _,a=self.call("POST","/v1/accounts"); _,b=self.call("POST","/v1/accounts")
        a,b=a["token"],b["token"]
        recipe={"name":"Суп","category":"soups","instructions":"Варить","cooked_weight":200,"servings":2,"ingredients":[{"name":"Овощи","grams":200,"kcal":100,"p":3,"f":1,"c":20}],"profile":"secret","photo":"secret"}
        self.assertEqual(self.call("POST","/v1/recipes",{"recipe":recipe},a)[0],400)
        code,res=self.call("POST","/v1/recipes",{"recipe":recipe,"consent":True},a)
        self.assertEqual(code,200); rid=res["id"]
        self.assertEqual(self.call("GET","/v1/recipes")[1]["items"],[])
        self.assertEqual(self.call("GET","/v1/mine",token=a)[1]["items"][0]["status"],"pending")
        with server.db() as conn: conn.execute("UPDATE recipes SET status='approved' WHERE id=?",(rid,))
        items=self.call("GET","/v1/recipes",query="category=soups&max_kcal=200")[1]["items"]
        self.assertEqual(len(items),1); self.assertEqual(items[0]["kcal"],100)
        self.assertNotIn("profile",items[0]["recipe"]); self.assertNotIn("photo",items[0]["recipe"])
        self.assertEqual(self.call("GET","/v1/recipes",query="category=desserts")[1]["items"],[])
        self.assertEqual(self.call("POST",f"/v1/recipes/{rid}/rating",{"score":5},a)[0],400)
        for score in (5,3): self.assertEqual(self.call("POST",f"/v1/recipes/{rid}/rating",{"score":score},b)[0],200)
        item=self.call("GET","/v1/recipes")[1]["items"][0]
        self.assertEqual((item["rating"],item["votes"]),(3.0,1))
        self.assertEqual(self.call("POST",f"/v1/recipes/{rid}/report",{"reason":"Spam"},b)[0],200)
        self.assertEqual(self.call("DELETE",f"/v1/recipes/{rid}",token=b)[0],404)
        self.assertEqual(self.call("DELETE","/v1/account",token=a)[0],200)
        self.assertEqual(self.call("GET","/v1/recipes")[1]["items"],[])
if __name__=="__main__": unittest.main()
