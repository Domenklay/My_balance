extends RefCounted
# Adapted recipe ideas with explicit estimated quantities, yields and generic nutrition.
# Source attribution is kept per recipe. No third-party photos or copied articles.
const SOURCE_HOME = "https://ru.wikibooks.org/wiki/Кулинарная_книга"
const LICENSE = "https://creativecommons.org/licenses/by-sa/4.0/"
const RECIPES = [
    {
        "id": "catalog_oats",
        "name": "Овсяная каша на молоке",
        "category": "breakfast",
        "cooked_weight": 310,
        "servings": 1,
        "instructions": "Соедини молоко и воду, нагрей. Всыпь хлопья и готовь при слабом кипении по времени на упаковке. Вмешай масло.",
        "source_url": "https://ru.wikibooks.org/wiki/%D0%A0%D0%B5%D1%86%D0%B5%D0%BF%D1%82%3A%D0%9E%D0%B2%D1%81%D1%8F%D0%BD%D0%B0%D1%8F_%D0%BA%D0%B0%D1%88%D0%B0",
        "ingredients": [
            {
                "name": "Овсяные хлопья (сухие)",
                "grams": 45,
                "kcal": 370,
                "p": 13,
                "f": 7,
                "c": 62
            },
            {
                "name": "Молоко 2,5%",
                "grams": 200,
                "kcal": 52,
                "p": 3,
                "f": 2.5,
                "c": 4.7
            },
            {
                "name": "Вода",
                "grams": 100,
                "kcal": 0,
                "p": 0,
                "f": 0,
                "c": 0
            },
            {
                "name": "Сливочное масло",
                "grams": 5,
                "kcal": 748,
                "p": 0.5,
                "f": 82,
                "c": 0.8
            }
        ]
    },
    {
        "id": "catalog_omelet",
        "name": "Омлет с помидорами",
        "category": "breakfast",
        "cooked_weight": 215,
        "servings": 1,
        "instructions": "Взбей яйца с молоком. На смазанной сковороде прогрей нарезанные помидоры, влей яйца. Готовь под крышкой до полного схватывания.",
        "source_url": "https://ru.wikibooks.org/wiki/%D0%A0%D0%B5%D1%86%D0%B5%D0%BF%D1%82%3A%D0%9E%D0%BC%D0%BB%D0%B5%D1%82",
        "ingredients": [
            {
                "name": "Яйцо без скорлупы",
                "grams": 100,
                "kcal": 143,
                "p": 12.6,
                "f": 9.5,
                "c": 0.7
            },
            {
                "name": "Помидоры",
                "grams": 100,
                "kcal": 18,
                "p": 0.9,
                "f": 0.2,
                "c": 3.9
            },
            {
                "name": "Молоко 2,5%",
                "grams": 40,
                "kcal": 52,
                "p": 3,
                "f": 2.5,
                "c": 4.7
            },
            {
                "name": "Растительное масло",
                "grams": 5,
                "kcal": 884,
                "p": 0,
                "f": 100,
                "c": 0
            }
        ]
    },
    {
        "id": "catalog_fresh_salad",
        "name": "Салат из помидоров и огурцов",
        "category": "salads",
        "cooked_weight": 310,
        "servings": 2,
        "instructions": "Нарежь свежие овощи, перемешай с маслом. Подавай сразу.",
        "source_url": "https://ru.wikibooks.org/wiki/%D0%A0%D0%B5%D1%86%D0%B5%D0%BF%D1%82%3A%D0%A1%D0%B0%D0%BB%D0%B0%D1%82_%D0%B8%D0%B7_%D0%BF%D0%BE%D0%BC%D0%B8%D0%B4%D0%BE%D1%80%D0%BE%D0%B2_%D0%B8_%D0%BE%D0%B3%D1%83%D1%80%D1%86%D0%BE%D0%B2",
        "ingredients": [
            {
                "name": "Помидоры",
                "grams": 150,
                "kcal": 18,
                "p": 0.9,
                "f": 0.2,
                "c": 3.9
            },
            {
                "name": "Огурцы",
                "grams": 150,
                "kcal": 15,
                "p": 0.7,
                "f": 0.1,
                "c": 3.6
            },
            {
                "name": "Растительное масло",
                "grams": 10,
                "kcal": 884,
                "p": 0,
                "f": 100,
                "c": 0
            }
        ]
    },
    {
        "id": "catalog_cucumber_salad",
        "name": "Огуречный салат с зеленью",
        "category": "salads",
        "cooked_weight": 270,
        "servings": 2,
        "instructions": "Нарежь огурцы, измельчи зелень. Заправь маслом и перемешай.",
        "source_url": "https://ru.wikibooks.org/wiki/%D0%A0%D0%B5%D1%86%D0%B5%D0%BF%D1%82%3A%D0%A1%D0%B0%D0%BB%D0%B0%D1%82_%D0%B8%D0%B7_%D0%BE%D0%B3%D1%83%D1%80%D1%86%D0%BE%D0%B2_%D1%81_%D0%B7%D0%B5%D0%BB%D1%91%D0%BD%D1%8B%D0%BC_%D0%BB%D1%83%D0%BA%D0%BE%D0%BC_%D0%B8_%D1%83%D0%BA%D1%80%D0%BE%D0%BF%D0%BE%D0%BC",
        "ingredients": [
            {
                "name": "Огурцы",
                "grams": 230,
                "kcal": 15,
                "p": 0.7,
                "f": 0.1,
                "c": 3.6
            },
            {
                "name": "Зелёный лук",
                "grams": 20,
                "kcal": 32,
                "p": 1.8,
                "f": 0.2,
                "c": 7.3
            },
            {
                "name": "Укроп",
                "grams": 10,
                "kcal": 43,
                "p": 3.5,
                "f": 1.1,
                "c": 7
            },
            {
                "name": "Растительное масло",
                "grams": 10,
                "kcal": 884,
                "p": 0,
                "f": 100,
                "c": 0
            }
        ]
    },
    {
        "id": "catalog_vinaigrette",
        "name": "Винегрет с картофелем",
        "category": "salads",
        "cooked_weight": 650,
        "servings": 4,
        "instructions": "Отвари свёклу, картофель и морковь, остуди и очисти. Нарежь кубиками, добавь огурец и лук. Заправь маслом.",
        "source_url": "https://ru.wikibooks.org/wiki/%D0%A0%D0%B5%D1%86%D0%B5%D0%BF%D1%82%3A%D0%92%D0%B8%D0%BD%D0%B5%D0%B3%D1%80%D0%B5%D1%82",
        "ingredients": [
            {
                "name": "Свёкла",
                "grams": 200,
                "kcal": 43,
                "p": 1.6,
                "f": 0.2,
                "c": 9.6
            },
            {
                "name": "Картофель",
                "grams": 200,
                "kcal": 77,
                "p": 2,
                "f": 0.1,
                "c": 17
            },
            {
                "name": "Морковь",
                "grams": 100,
                "kcal": 41,
                "p": 0.9,
                "f": 0.2,
                "c": 9.6
            },
            {
                "name": "Огурцы солёные",
                "grams": 100,
                "kcal": 12,
                "p": 0.5,
                "f": 0.2,
                "c": 2.4
            },
            {
                "name": "Лук репчатый",
                "grams": 50,
                "kcal": 40,
                "p": 1.1,
                "f": 0.1,
                "c": 9.3
            },
            {
                "name": "Растительное масло",
                "grams": 20,
                "kcal": 884,
                "p": 0,
                "f": 100,
                "c": 0
            }
        ]
    },
    {
        "id": "catalog_syrniki",
        "name": "Творожные сырники",
        "category": "desserts",
        "cooked_weight": 310,
        "servings": 3,
        "instructions": "Разотри творог с яйцом и сахаром, добавь часть муки. Сформируй небольшие сырники, используй остаток муки для обваливания. Обжарь до полной готовности на умеренном огне.",
        "source_url": "https://ru.wikibooks.org/wiki/%D0%A0%D0%B5%D1%86%D0%B5%D0%BF%D1%82%3A%D0%A1%D1%8B%D1%80%D0%BD%D0%B8%D0%BA%D0%B8",
        "ingredients": [
            {
                "name": "Творог 5%",
                "grams": 250,
                "kcal": 121,
                "p": 17,
                "f": 5,
                "c": 3
            },
            {
                "name": "Яйцо без скорлупы",
                "grams": 50,
                "kcal": 143,
                "p": 12.6,
                "f": 9.5,
                "c": 0.7
            },
            {
                "name": "Мука пшеничная",
                "grams": 40,
                "kcal": 364,
                "p": 10.3,
                "f": 1,
                "c": 76
            },
            {
                "name": "Сахар",
                "grams": 15,
                "kcal": 400,
                "p": 0,
                "f": 0,
                "c": 100
            },
            {
                "name": "Растительное масло",
                "grams": 8,
                "kcal": 884,
                "p": 0,
                "f": 100,
                "c": 0
            }
        ]
    },
    {
        "id": "catalog_buckwheat",
        "name": "Гречка со сливочным маслом",
        "category": "mains",
        "cooked_weight": 360,
        "servings": 2,
        "instructions": "Промой крупу, залей водой. Вари под крышкой на слабом огне до мягкости. Добавь сливочное масло.",
        "source_url": "https://ru.wikibooks.org/wiki/%D0%A0%D0%B5%D1%86%D0%B5%D0%BF%D1%82%3A%D0%93%D1%80%D0%B5%D1%87%D0%BD%D0%B5%D0%B2%D0%B0%D1%8F_%D0%BA%D0%B0%D1%88%D0%B0",
        "ingredients": [
            {
                "name": "Гречневая крупа (сухая)",
                "grams": 120,
                "kcal": 343,
                "p": 13.3,
                "f": 3.4,
                "c": 71.5
            },
            {
                "name": "Вода",
                "grams": 260,
                "kcal": 0,
                "p": 0,
                "f": 0,
                "c": 0
            },
            {
                "name": "Сливочное масло",
                "grams": 10,
                "kcal": 748,
                "p": 0.5,
                "f": 82,
                "c": 0.8
            }
        ]
    },
    {
        "id": "catalog_snezhanka",
        "name": "Йогуртовый салат «Снежанка»",
        "category": "snacks",
        "cooked_weight": 450,
        "servings": 3,
        "instructions": "Мелко нарежь огурец, измельчи чеснок, орехи и укроп. Смешай с густым йогуртом и маслом. Охлади.",
        "source_url": "https://ru.wikibooks.org/wiki/%D0%A0%D0%B5%D1%86%D0%B5%D0%BF%D1%82%3A%D0%A1%D0%B0%D0%BB%D0%B0%D1%82_%D0%A1%D0%BD%D0%B5%D0%B6%D0%B0%D0%BD%D0%BA%D0%B0",
        "ingredients": [
            {
                "name": "Густой натуральный йогурт 2%",
                "grams": 250,
                "kcal": 73,
                "p": 9,
                "f": 2,
                "c": 4
            },
            {
                "name": "Огурцы",
                "grams": 180,
                "kcal": 15,
                "p": 0.7,
                "f": 0.1,
                "c": 3.6
            },
            {
                "name": "Чеснок",
                "grams": 5,
                "kcal": 149,
                "p": 6.4,
                "f": 0.5,
                "c": 33
            },
            {
                "name": "Грецкие орехи",
                "grams": 15,
                "kcal": 654,
                "p": 15.2,
                "f": 65.2,
                "c": 13.7
            },
            {
                "name": "Растительное масло",
                "grams": 5,
                "kcal": 884,
                "p": 0,
                "f": 100,
                "c": 0
            },
            {
                "name": "Укроп",
                "grams": 5,
                "kcal": 43,
                "p": 3.5,
                "f": 1.1,
                "c": 7
            }
        ]
    },
    {
        "id": "catalog_shopska",
        "name": "Шопский салат",
        "category": "salads",
        "cooked_weight": 515,
        "servings": 3,
        "instructions": "Нарежь овощи и зелень, заправь маслом. Сверху раскроши брынзу.",
        "source_url": "https://ru.wikibooks.org/wiki/%D0%A0%D0%B5%D1%86%D0%B5%D0%BF%D1%82%3A%D0%A1%D0%B0%D0%BB%D0%B0%D1%82_%D0%A8%D0%BE%D0%BF%D1%81%D0%BA%D0%B8%D0%B9",
        "ingredients": [
            {
                "name": "Помидоры",
                "grams": 200,
                "kcal": 18,
                "p": 0.9,
                "f": 0.2,
                "c": 3.9
            },
            {
                "name": "Огурцы",
                "grams": 150,
                "kcal": 15,
                "p": 0.7,
                "f": 0.1,
                "c": 3.6
            },
            {
                "name": "Сладкий перец",
                "grams": 80,
                "kcal": 31,
                "p": 1,
                "f": 0.3,
                "c": 6
            },
            {
                "name": "Лук репчатый",
                "grams": 30,
                "kcal": 40,
                "p": 1.1,
                "f": 0.1,
                "c": 9.3
            },
            {
                "name": "Брынза",
                "grams": 60,
                "kcal": 260,
                "p": 17,
                "f": 21,
                "c": 2
            },
            {
                "name": "Растительное масло",
                "grams": 10,
                "kcal": 884,
                "p": 0,
                "f": 100,
                "c": 0
            },
            {
                "name": "Петрушка",
                "grams": 5,
                "kcal": 36,
                "p": 3,
                "f": 0.8,
                "c": 6.3
            }
        ]
    },
    {
        "id": "catalog_fattoush",
        "name": "Фаттуш с питой",
        "category": "salads",
        "cooked_weight": 530,
        "servings": 2,
        "instructions": "Нарежь питу и подрумянь на части масла. Смешай нарезанные овощи с зеленью, лимонным соком и остатком масла. Добавь питу перед подачей.",
        "source_url": "https://ru.wikibooks.org/wiki/%D0%A0%D0%B5%D1%86%D0%B5%D0%BF%D1%82%3A%D0%A4%D0%B0%D1%82%D1%82%D1%83%D1%88",
        "ingredients": [
            {
                "name": "Помидоры",
                "grams": 150,
                "kcal": 18,
                "p": 0.9,
                "f": 0.2,
                "c": 3.9
            },
            {
                "name": "Огурцы",
                "grams": 150,
                "kcal": 15,
                "p": 0.7,
                "f": 0.1,
                "c": 3.6
            },
            {
                "name": "Сладкий перец",
                "grams": 100,
                "kcal": 31,
                "p": 1,
                "f": 0.3,
                "c": 6
            },
            {
                "name": "Пита",
                "grams": 80,
                "kcal": 275,
                "p": 9,
                "f": 1.2,
                "c": 56
            },
            {
                "name": "Растительное масло",
                "grams": 15,
                "kcal": 884,
                "p": 0,
                "f": 100,
                "c": 0
            },
            {
                "name": "Лимонный сок",
                "grams": 20,
                "kcal": 22,
                "p": 0.4,
                "f": 0.2,
                "c": 6.9
            },
            {
                "name": "Петрушка",
                "grams": 10,
                "kcal": 36,
                "p": 3,
                "f": 0.8,
                "c": 6.3
            }
        ]
    },
    {
        "id": "catalog_onion_soup",
        "name": "Луковый суп с сыром",
        "category": "soups",
        "cooked_weight": 850,
        "servings": 3,
        "instructions": "Томи нарезанный лук в масле до золотистого оттенка. Вмешай муку, постепенно влей бульон и вари до мягкости. Подавай с подсушенным хлебом и сыром.",
        "source_url": "https://ru.wikibooks.org/wiki/%D0%A0%D0%B5%D1%86%D0%B5%D0%BF%D1%82%3A%D0%9B%D1%83%D0%BA%D0%BE%D0%B2%D1%8B%D0%B9_%D1%81%D1%83%D0%BF",
        "ingredients": [
            {
                "name": "Лук репчатый",
                "grams": 350,
                "kcal": 40,
                "p": 1.1,
                "f": 0.1,
                "c": 9.3
            },
            {
                "name": "Сливочное масло",
                "grams": 20,
                "kcal": 748,
                "p": 0.5,
                "f": 82,
                "c": 0.8
            },
            {
                "name": "Мука пшеничная",
                "grams": 10,
                "kcal": 364,
                "p": 10.3,
                "f": 1,
                "c": 76
            },
            {
                "name": "Овощной бульон",
                "grams": 600,
                "kcal": 8,
                "p": 0.3,
                "f": 0.1,
                "c": 1
            },
            {
                "name": "Хлеб пшеничный",
                "grams": 60,
                "kcal": 265,
                "p": 9,
                "f": 3.2,
                "c": 49
            },
            {
                "name": "Твёрдый сыр",
                "grams": 45,
                "kcal": 380,
                "p": 26,
                "f": 30,
                "c": 1
            }
        ]
    },
    {
        "id": "catalog_compote",
        "name": "Яблочный компот с мякотью",
        "category": "drinks",
        "cooked_weight": 1080,
        "servings": 4,
        "instructions": "Нарежь яблоки, удали сердцевину. Вскипяти воду с сахаром, добавь фрукты и вари до мягкости. Подавай вместе с яблоками: расчёт включает мякоть.",
        "source_url": "https://ru.wikibooks.org/wiki/%D0%A0%D0%B5%D1%86%D0%B5%D0%BF%D1%82%3A%D0%9A%D0%BE%D0%BC%D0%BF%D0%BE%D1%82",
        "ingredients": [
            {
                "name": "Яблоки",
                "grams": 300,
                "kcal": 52,
                "p": 0.3,
                "f": 0.2,
                "c": 13.8
            },
            {
                "name": "Вода",
                "grams": 800,
                "kcal": 0,
                "p": 0,
                "f": 0,
                "c": 0
            },
            {
                "name": "Сахар",
                "grams": 25,
                "kcal": 400,
                "p": 0,
                "f": 0,
                "c": 100
            }
        ]
    },
    {
        "id": "catalog_vinaigrette_sauce",
        "name": "Заправка винегрет",
        "category": "sauces",
        "cooked_weight": 80,
        "servings": 8,
        "instructions": "Соедини уксус и масло, взбей вилкой до временной эмульсии. Перемешай перед добавлением в салат.",
        "source_url": "https://ru.wikibooks.org/wiki/%D0%A0%D0%B5%D1%86%D0%B5%D0%BF%D1%82%3A%D0%A1%D0%BE%D1%83%D1%81_%D0%92%D0%B8%D0%BD%D0%B5%D0%B3%D1%80%D0%B5%D1%82",
        "ingredients": [
            {
                "name": "Растительное масло",
                "grams": 60,
                "kcal": 884,
                "p": 0,
                "f": 100,
                "c": 0
            },
            {
                "name": "Уксус столовый",
                "grams": 20,
                "kcal": 18,
                "p": 0,
                "f": 0,
                "c": 0.04
            }
        ]
    },
    {
        "id": "catalog_chicken_rice",
        "name": "Курица с рисом",
        "category": "mains",
        "cooked_weight": 550,
        "servings": 2,
        "instructions": "Отвари рис. Нарежь курицу, обжарь на масле до полной готовности, добавь морковь и смешай с рисом.",
        "source_url": "https://ru.wikibooks.org/wiki/Кулинарная_книга",
        "original_recipe": true,
        "ingredients": [
            {
                "name": "Куриная грудка сырая",
                "grams": 250,
                "kcal": 120,
                "p": 22.5,
                "f": 2.6,
                "c": 0
            },
            {
                "name": "Рис сухой",
                "grams": 100,
                "kcal": 350,
                "p": 7,
                "f": 0.7,
                "c": 78
            },
            {
                "name": "Морковь",
                "grams": 80,
                "kcal": 41,
                "p": 0.9,
                "f": 0.2,
                "c": 9.6
            },
            {
                "name": "Растительное масло",
                "grams": 8,
                "kcal": 884,
                "p": 0,
                "f": 100,
                "c": 0
            },
            {
                "name": "Вода",
                "grams": 220,
                "kcal": 0,
                "p": 0,
                "f": 0,
                "c": 0
            }
        ]
    },
    {
        "id": "catalog_lentil_soup",
        "name": "Чечевичный суп",
        "category": "soups",
        "cooked_weight": 920,
        "servings": 3,
        "instructions": "Промой чечевицу. Нарежь овощи, прогрей лук и морковь в масле, залей водой. Добавь чечевицу и вари до мягкости.",
        "source_url": "https://ru.wikibooks.org/wiki/Кулинарная_книга",
        "original_recipe": true,
        "ingredients": [
            {
                "name": "Красная чечевица сухая",
                "grams": 120,
                "kcal": 352,
                "p": 24.6,
                "f": 1.1,
                "c": 63.4
            },
            {
                "name": "Морковь",
                "grams": 100,
                "kcal": 41,
                "p": 0.9,
                "f": 0.2,
                "c": 9.6
            },
            {
                "name": "Лук",
                "grams": 70,
                "kcal": 40,
                "p": 1.1,
                "f": 0.1,
                "c": 9.3
            },
            {
                "name": "Масло",
                "grams": 8,
                "kcal": 884,
                "p": 0,
                "f": 100,
                "c": 0
            },
            {
                "name": "Вода",
                "grams": 700,
                "kcal": 0,
                "p": 0,
                "f": 0,
                "c": 0
            }
        ]
    },
    {
        "id": "catalog_apple_curd",
        "name": "Творог с яблоком",
        "category": "snacks",
        "cooked_weight": 260,
        "servings": 1,
        "instructions": "Нарежь яблоко и смешай с творогом и йогуртом.",
        "source_url": "https://ru.wikibooks.org/wiki/Кулинарная_книга",
        "original_recipe": true,
        "ingredients": [
            {
                "name": "Творог 5%",
                "grams": 150,
                "kcal": 121,
                "p": 17,
                "f": 5,
                "c": 3
            },
            {
                "name": "Яблоко",
                "grams": 80,
                "kcal": 52,
                "p": 0.3,
                "f": 0.2,
                "c": 13.8
            },
            {
                "name": "Йогурт натуральный",
                "grams": 30,
                "kcal": 73,
                "p": 9,
                "f": 2,
                "c": 4
            }
        ]
    },
    {
        "id": "catalog_banana_pancakes",
        "name": "Банановые оладьи",
        "category": "breakfast",
        "cooked_weight": 210,
        "servings": 2,
        "instructions": "Разомни банан, смешай с яйцом и мукой. Жарь небольшие оладьи на умеренном огне до полной готовности.",
        "source_url": "https://ru.wikibooks.org/wiki/Кулинарная_книга",
        "original_recipe": true,
        "ingredients": [
            {
                "name": "Банан",
                "grams": 100,
                "kcal": 89,
                "p": 1.1,
                "f": 0.3,
                "c": 22.8
            },
            {
                "name": "Яйцо",
                "grams": 50,
                "kcal": 143,
                "p": 12.6,
                "f": 9.5,
                "c": 0.7
            },
            {
                "name": "Мука",
                "grams": 50,
                "kcal": 364,
                "p": 10.3,
                "f": 1,
                "c": 76
            },
            {
                "name": "Молоко",
                "grams": 30,
                "kcal": 52,
                "p": 3,
                "f": 2.5,
                "c": 4.7
            },
            {
                "name": "Масло",
                "grams": 5,
                "kcal": 884,
                "p": 0,
                "f": 100,
                "c": 0
            }
        ]
    },
    {
        "id": "catalog_apple_muffins",
        "name": "Яблочные кексы",
        "category": "baking",
        "cooked_weight": 380,
        "servings": 4,
        "instructions": "Смешай яйцо, молоко, сахар и масло. Добавь муку с разрыхлителем и нарезанные яблоки. Выпекай при 180 °C до сухой шпажки.",
        "source_url": "https://ru.wikibooks.org/wiki/Кулинарная_книга",
        "original_recipe": true,
        "ingredients": [
            {
                "name": "Яблоки",
                "grams": 180,
                "kcal": 52,
                "p": 0.3,
                "f": 0.2,
                "c": 13.8
            },
            {
                "name": "Мука",
                "grams": 100,
                "kcal": 364,
                "p": 10.3,
                "f": 1,
                "c": 76
            },
            {
                "name": "Яйцо",
                "grams": 50,
                "kcal": 143,
                "p": 12.6,
                "f": 9.5,
                "c": 0.7
            },
            {
                "name": "Молоко",
                "grams": 60,
                "kcal": 52,
                "p": 3,
                "f": 2.5,
                "c": 4.7
            },
            {
                "name": "Сахар",
                "grams": 20,
                "kcal": 400,
                "p": 0,
                "f": 0,
                "c": 100
            },
            {
                "name": "Масло",
                "grams": 15,
                "kcal": 884,
                "p": 0,
                "f": 100,
                "c": 0
            },
            {
                "name": "Разрыхлитель",
                "grams": 4,
                "kcal": 53,
                "p": 0,
                "f": 0,
                "c": 28
            }
        ]
    },
    {
        "id": "catalog_berry_yogurt",
        "name": "Йогурт с ягодами",
        "category": "desserts",
        "cooked_weight": 220,
        "servings": 1,
        "instructions": "Смешай йогурт с ягодами и овсяными хлопьями. Охлади перед подачей.",
        "source_url": "https://ru.wikibooks.org/wiki/Кулинарная_книга",
        "original_recipe": true,
        "ingredients": [
            {
                "name": "Йогурт натуральный",
                "grams": 150,
                "kcal": 73,
                "p": 9,
                "f": 2,
                "c": 4
            },
            {
                "name": "Клубника",
                "grams": 50,
                "kcal": 32,
                "p": 0.7,
                "f": 0.3,
                "c": 7.7
            },
            {
                "name": "Овсяные хлопья",
                "grams": 20,
                "kcal": 370,
                "p": 13,
                "f": 7,
                "c": 62
            }
        ]
    }
]

static func all() -> Array:
    return RECIPES.duplicate(true)

static func personal_copy(recipe: Dictionary) -> Dictionary:
    var copy = recipe.duplicate(true)
    copy["id"] = "saved_" + str(recipe["id"])
    if recipe.get("original_recipe", false):
        copy["instructions"] = str(copy["instructions"]) + "\n\nРецепт редакции «Мой баланс». КБЖУ и выход приблизительные; уточни продукты и фактический вес."
        return copy
    copy["instructions"] = str(copy["instructions"]) + "\n\nАдаптация: участники Викиучебника, CC BY-SA. Источник: " + str(recipe["source_url"]) + "\nКБЖУ и выход приблизительные; уточни продукты и фактический вес."
    return copy
