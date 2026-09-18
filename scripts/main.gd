extends Node2D

const FLOOR_Y = 620.0
const MAX_BODIES = 140
const ROBOTS = ["robot","robot_scout","robot_titan","robot_jumper","robot_magnet","robot_tesla","robot_bomber","robot_medic","robot_antigrav","robot_runner","robot_acrobat"]
const GADGETS = ["magnet","fan","coil","sticky","glass","trampoline","bumper","weight","balloon","wheel"]
const WEAPONS = ["pistol","revolver","rifle","shotgun","sawed","nailgun","grenade","turret","flak"]
const EXOTIC = ["railgun","crossbow","rocket_gun","flamer","freezer","tesla_gun","harpoon","glue_gun","bouncer","cannon","minigun","pulse_gun","grapple","mine_gun","balloon_gun","vortex","disc_gun","taser","cluster","wind_gun","extinguisher"]
const MELEE = ["sword","axe","spear","hammer","knife","katana","scythe","mace","chainsaw","bat","whip","plasma_blade","crowbar","halberd","hook","torch"]
# Стихии: три лужи и четыре источника огня и тока.
const ELEMENTS = ["water_pool","oil_pool","acid_pool","gas_can","battery","cable","firework"]
const PARTS = ["c_beam","c_beam_long","c_girder","c_plate","c_board","c_block","c_corner","c_triangle","c_pipe","c_frame","c_platform","c_counterweight","c_hinge","c_axle","c_motor","c_spring","c_jet","c_balloon","c_spikes","c_wing"]
const VEHICLES = ["car_sedan","car_pickup","car_monster","car_tank","car_sport","car_bus","car_mixer","car_jeep","car_ambulance","car_fire","car_police","car_dozer","car_tractor","car_moto","car_atv","car_kart","car_limo","car_apc","car_heli"]
const FLUIDS = ["water_pool","oil_pool","acid_pool"]
# Плотность жидкости в тех же единицах, что и масса тела на его площадь.
# Подобрана так, что дерево, лёд и пробка всплывают, а металл и свинец тонут.
const FLUID_DENSITY = 0.0060
const VIRUSES = ["virus_rage","virus_dance","virus_panic","virus_guard","virus_leap","virus_orbit","virus_float","virus_hunter","virus_follow","virus_spin"]
const TOYS = [
	"rubber","ice","soap","sponge","anvil","feather","spring_block","pillow","slime","cork",
	"brick","crystal","tire","gyro","dice","sandbag","gel","lead","paper","honeycomb",
	"conveyor","spinner_pad","updraft","chiller","vacuum_box","shaker","pulsar","lift","speaker","grav_well",
	"hover_pad","zapper","metronome","pump","scatter_pad","slow_field","boost_pad","rotator","magnet_pad","thump"
]
const EPHEMERAL = ["slug","nail","emp","debris","rocket","chill","bounce","disc","flame","cannonball","tether","foam","ember"]
const ITEMS = [
	"robot","crate","barrel","ball","plank","metal","thruster","mine",
	"robot_scout","robot_titan","robot_jumper","robot_magnet","robot_tesla","robot_bomber","robot_medic","robot_antigrav","robot_runner","robot_acrobat",
	"magnet","fan","coil","sticky","glass","trampoline","bumper","weight","balloon","wheel","drone",
	"c4","laser_cutter","singularity","syringe_life","syringe_acid","syringe_nitro","syringe_overclock","syringe_freeze",
	"pistol","revolver","rifle","shotgun","sawed","nailgun","grenade","turret","flak",
	"sword","axe","spear","hammer","knife","katana","scythe","mace","chainsaw","bat","whip","plasma_blade","crowbar","halberd","hook",
	"railgun","crossbow","rocket_gun","flamer","freezer","tesla_gun","harpoon","glue_gun","bouncer","cannon","minigun","pulse_gun","grapple","mine_gun","balloon_gun","vortex","disc_gun","taser","cluster","wind_gun",
	"virus_rage","virus_dance","virus_panic","virus_guard","virus_leap","virus_orbit","virus_float","virus_hunter","virus_follow","virus_spin",
	"rubber","ice","soap","sponge","anvil","feather","spring_block","pillow","slime","cork",
	"brick","crystal","tire","gyro","dice","sandbag","gel","lead","paper","honeycomb",
	"conveyor","spinner_pad","updraft","chiller","vacuum_box","shaker","pulsar","lift","speaker","grav_well",
	"hover_pad","zapper","metronome","pump","scatter_pad","slow_field","boost_pad","rotator","magnet_pad","thump",
	"water_pool","oil_pool","acid_pool","gas_can","battery","cable","firework","torch","extinguisher",
	"car_sedan","car_pickup","car_monster","car_tank",
	"car_sport","car_bus","car_mixer","car_jeep","car_ambulance","car_fire","car_police","car_dozer","car_tractor","car_moto","car_atv","car_kart","car_limo","car_apc","car_heli",
	"c_beam","c_beam_long","c_girder","c_plate","c_board","c_block","c_corner","c_triangle","c_pipe","c_frame","c_platform","c_counterweight","c_hinge","c_axle","c_motor","c_spring","c_jet","c_balloon","c_spikes","c_wing"
]
const CATALOG = [
	["robots","Роботы","Robots",ROBOTS],
	["viruses","Вирусы","Viruses",VIRUSES],
	["parts","Детали","Parts",["crate","barrel","ball","plank","metal","glass","weight"]],
	["gadgets","Гаджеты","Gadgets",["thruster","mine","magnet","c4","laser_cutter","singularity","fan","coil","sticky","trampoline","bumper","balloon","wheel","drone"]],
	["toys","Игрушки","Toys",TOYS],
	["weapons","Оружие","Guns",WEAPONS],
	["exotic","Экзотика","Exotic",EXOTIC],
	["melee","Холодное","Melee",MELEE],
	["syringes","Шприцы","Syringes",["syringe_life","syringe_acid","syringe_nitro","syringe_overclock","syringe_freeze"]],
	["elements","Стихии","Elements",ELEMENTS],
	["vehicles","Машины","Vehicles",VEHICLES],
	["parts_kit","Конструктор","Builder",PARTS]
]

# Горючесть: 0 — не горит, 1 — обычное дерево. Чем больше, тем быстрее
# занимается и тем злее жар. Всё, чего нет в таблице, не горит.
const FLAMMABLE = {
	"crate":1.0,"plank":1.15,"paper":2.4,"pillow":1.5,"sponge":1.3,"honeycomb":1.6,
	"barrel":0.9,"gas_can":2.6,"oil_pool":2.2,"cork":1.2,"tire":0.8,"slime":0.5,
	"balloon":1.8,"firework":2.0,"torch":0.0,"virus_rage":0.0,
	"head":0.45,"torso":0.45,"pelvis":0.45,"arm":0.45,"leg":0.45,
	"car_sedan":0.35,"car_pickup":0.35,"car_monster":0.4,"car_tank":0.2,
	"car_sport":0.35,"car_bus":0.4,"car_mixer":0.3,"car_jeep":0.35,"car_ambulance":0.35,"car_fire":0.3,"car_police":0.35,"car_dozer":0.2,"car_tractor":0.4,"car_moto":0.5,"car_atv":0.5,"car_kart":0.6,"car_limo":0.35,"car_apc":0.2,"car_heli":0.45,
	"c_board":1.1,"c_balloon":1.6,"c_axle":0.5
}
# Проводимость: 0 — изолятор, 1 — чистый проводник. Резина, стекло и дерево
# ток не пускают, металл, вода и сами роботы пускают охотно.
const CONDUCTIVE = {
	"metal":1.0,"cable":1.0,"battery":1.0,"coil":0.9,"magnet":0.9,"wheel":0.8,
	"anvil":1.0,"lead":1.0,"weight":0.9,"turret":0.8,"water_pool":1.0,"acid_pool":0.9,
	"head":0.85,"torso":0.85,"pelvis":0.85,"arm":0.85,"leg":0.85,
	"sword":0.9,"axe":0.85,"spear":0.9,"hammer":0.8,"knife":0.9,"katana":0.9,
	"scythe":0.85,"mace":0.8,"crowbar":0.95,"halberd":0.85,"hook":0.9,"drone":0.7,
	"car_sedan":0.8,"car_pickup":0.8,"car_monster":0.8,"car_tank":1.0,
	"car_sport":0.8,"car_bus":0.8,"car_mixer":0.9,"car_jeep":0.8,"car_ambulance":0.8,"car_fire":0.8,"car_police":0.8,"car_dozer":1.0,"car_tractor":0.8,"car_moto":0.7,"car_atv":0.6,"car_kart":0.5,"car_limo":0.8,"car_apc":1.0,"car_heli":0.7,
	"c_beam":1.0,"c_beam_long":1.0,"c_girder":1.0,"c_plate":1.0,"c_block":1.0,"c_corner":1.0,"c_triangle":1.0,"c_pipe":1.0,"c_frame":1.0,"c_platform":0.9,"c_counterweight":1.0,"c_hinge":1.0,"c_motor":0.9,"c_spring":1.0,"c_jet":0.9,"c_spikes":1.0,"c_wing":0.8
}
const TOY_PHYS = {
	"rubber":{"w":44,"h":44,"mass":3.0,"hp":90.0,"bounce":0.96,"friction":0.2,"damp":0.12},
	"ice":{"w":52,"h":26,"mass":6.0,"hp":50.0,"bounce":0.05,"friction":0.04,"damp":0.08},
	"soap":{"w":40,"h":22,"mass":2.0,"hp":40.0,"bounce":0.35,"friction":0.02,"damp":0.1},
	"sponge":{"w":46,"h":34,"mass":1.1,"hp":55.0,"bounce":0.12,"friction":0.95,"damp":3.2,"adamp":6.0},
	"anvil":{"w":42,"h":28,"mass":72.0,"hp":400.0,"bounce":0.02,"friction":0.9,"damp":0.4},
	"feather":{"w":34,"h":18,"mass":0.18,"hp":20.0,"g":0.28,"bounce":0.1,"friction":0.4,"damp":1.6},
	"spring_block":{"w":50,"h":20,"mass":8.0,"hp":160.0,"bounce":0.4,"friction":0.5},
	"pillow":{"w":54,"h":30,"mass":1.8,"hp":70.0,"bounce":0.08,"friction":0.85,"damp":4.5,"adamp":7.0},
	"slime":{"w":44,"h":26,"mass":4.0,"hp":60.0,"bounce":0.15,"friction":1.2,"damp":2.4,"adamp":5.0},
	"cork":{"w":34,"h":34,"mass":0.7,"hp":35.0,"g":-0.18,"bounce":0.45,"friction":0.6,"circle":1.0},
	"brick":{"w":50,"h":24,"mass":18.0,"hp":180.0,"bounce":0.04,"friction":0.95},
	"crystal":{"w":34,"h":40,"mass":3.0,"hp":16.0,"bounce":0.2,"friction":0.3},
	"tire":{"w":48,"h":48,"mass":5.0,"hp":140.0,"bounce":0.58,"friction":1.15,"circle":1.0},
	"gyro":{"w":38,"h":38,"mass":6.0,"hp":120.0,"bounce":0.3,"friction":0.25,"adamp":0.22,"circle":1.0},
	"dice":{"w":30,"h":30,"mass":2.5,"hp":80.0,"bounce":0.25,"friction":0.55},
	"sandbag":{"w":48,"h":34,"mass":16.0,"hp":160.0,"bounce":0.03,"friction":1.1,"damp":2.8,"adamp":5.5},
	"gel":{"w":40,"h":40,"mass":2.4,"hp":50.0,"bounce":0.82,"friction":0.15,"damp":0.35,"circle":1.0},
	"lead":{"w":34,"h":34,"mass":58.0,"hp":320.0,"bounce":0.01,"friction":0.8,"damp":0.5},
	"paper":{"w":52,"h":8,"mass":0.22,"hp":12.0,"g":0.42,"bounce":0.05,"friction":0.5,"damp":2.0},
	"honeycomb":{"w":46,"h":40,"mass":1.4,"hp":45.0,"bounce":0.35,"friction":0.4,"damp":0.8},
	"conveyor":{"w":96,"h":16,"mass":22.0,"hp":220.0,"mode":"conveyor"},
	"spinner_pad":{"w":52,"h":52,"mass":12.0,"hp":180.0,"circle":1.0,"mode":"spin"},
	"updraft":{"w":48,"h":48,"mass":10.0,"hp":150.0,"mode":"updraft"},
	"chiller":{"w":50,"h":34,"mass":14.0,"hp":160.0,"mode":"chill"},
	"vacuum_box":{"w":52,"h":40,"mass":12.0,"hp":150.0,"mode":"vacuum"},
	"shaker":{"w":44,"h":44,"mass":9.0,"hp":140.0,"mode":"shake"},
	"pulsar":{"w":46,"h":46,"mass":11.0,"hp":150.0,"circle":1.0,"mode":"pulse"},
	"lift":{"w":72,"h":18,"mass":18.0,"hp":200.0,"mode":"lift"},
	"speaker":{"w":46,"h":40,"mass":10.0,"hp":140.0,"mode":"speaker"},
	"grav_well":{"w":50,"h":50,"mass":16.0,"hp":180.0,"circle":1.0,"mode":"well"},
	"hover_pad":{"w":72,"h":16,"mass":14.0,"hp":180.0,"mode":"hover"},
	"zapper":{"w":44,"h":44,"mass":11.0,"hp":140.0,"circle":1.0,"mode":"zap"},
	"metronome":{"w":26,"h":54,"mass":8.0,"hp":120.0,"mode":"metro"},
	"pump":{"w":48,"h":40,"mass":12.0,"hp":150.0,"mode":"pump"},
	"scatter_pad":{"w":62,"h":18,"mass":15.0,"hp":170.0,"mode":"scatter"},
	"slow_field":{"w":54,"h":54,"mass":13.0,"hp":160.0,"circle":1.0,"mode":"slow"},
	"boost_pad":{"w":70,"h":16,"mass":16.0,"hp":180.0,"mode":"boost"},
	"rotator":{"w":50,"h":50,"mass":12.0,"hp":150.0,"circle":1.0,"mode":"mix"},
	"magnet_pad":{"w":64,"h":18,"mass":15.0,"hp":170.0,"mode":"mag"},
	"thump":{"w":54,"h":22,"mass":14.0,"hp":160.0,"mode":"thump"}
}
const ITEM_NAMES = {
	"rubber":["Резина","Rubber"],"ice":["Лёд","Ice"],"soap":["Мыло","Soap"],"sponge":["Губка","Sponge"],
	"anvil":["Наковальня","Anvil"],"feather":["Перо","Feather"],"spring_block":["Пружина","Spring"],"pillow":["Подушка","Pillow"],
	"slime":["Слизь","Slime"],"cork":["Пробка","Cork"],"brick":["Кирпич","Brick"],"crystal":["Кристалл","Crystal"],
	"tire":["Шина","Tire"],"gyro":["Волчок","Top"],"dice":["Кость","Dice"],"sandbag":["Мешок","Sandbag"],
	"gel":["Гель","Gel"],"lead":["Свинец","Lead"],"paper":["Бумага","Paper"],"honeycomb":["Соты","Honeycomb"],
	"conveyor":["Конвейер","Conveyor"],"spinner_pad":["Вертушка","Spinner"],"updraft":["Восход","Updraft"],"chiller":["Охладитель","Chiller"],
	"vacuum_box":["Всасыватель","Vacuum"],"shaker":["Тряска","Shaker"],"pulsar":["Пульсар","Pulsar"],"lift":["Подъёмник","Lift"],
	"speaker":["Динамик","Speaker"],"grav_well":["Колодец","Well"],"hover_pad":["Антиграв","Hover pad"],"zapper":["Разрядник-плита","Zapper"],
	"metronome":["Метроном","Metronome"],"pump":["Насос","Pump"],"scatter_pad":["Разброс","Scatter"],"slow_field":["Тормоз","Slow field"],
	"boost_pad":["Ускоритель","Boost"],"rotator":["Мешалка","Mixer"],"magnet_pad":["Магнит-плита","Mag-plate"],"thump":["Толчок","Thump"],
	"c4":["Заряд C4","C4 Explosive"],"laser_cutter":["Лазерный резак","Laser Cutter"],"singularity":["Сингулярность","Singularity"],
	"syringe_life":["Шприц жизни","Life Syringe"],"syringe_acid":["Кислотный шприц","Acid Syringe"],"syringe_nitro":["Нитроглицерин","Nitro Syringe"],"syringe_overclock":["Оверклок","Overclock Syringe"],"syringe_freeze":["Крио-шприц","Cryo Syringe"],
	"water_pool":["Вода","Water"],"oil_pool":["Масло","Oil"],"acid_pool":["Кислота","Acid"],
	"gas_can":["Канистра","Fuel can"],"battery":["Батарея","Battery"],"cable":["Кабель","Cable"],
	"firework":["Фейерверк","Firework"],"torch":["Факел","Torch"],"extinguisher":["Огнетушитель","Extinguisher"],
	"car_sedan":["Легковушка","Sedan"],"car_pickup":["Пикап","Pickup"],"car_monster":["Монстр-трак","Monster truck"],"car_tank":["Танк","Tank"],
	"car_sport":["Спорткар","Sports car"],"car_bus":["Автобус","Bus"],"car_mixer":["Бетономешалка","Cement mixer"],"car_jeep":["Внедорожник","Off-roader"],
	"car_ambulance":["Скорая","Ambulance"],"car_fire":["Пожарная","Fire engine"],"car_police":["Полиция","Police car"],"car_dozer":["Бульдозер","Bulldozer"],
	"car_tractor":["Трактор","Tractor"],"car_moto":["Мотоцикл","Motorcycle"],"car_atv":["Квадроцикл","ATV"],"car_kart":["Картинг","Go-kart"],
	"car_limo":["Лимузин","Limousine"],"car_apc":["БТР","APC"],"car_heli":["Вертолёт","Helicopter"],
	"c_beam":["Балка","Beam"],"c_beam_long":["Длинная балка","Long beam"],"c_girder":["Ферма","Girder"],"c_plate":["Стальной лист","Steel plate"],
	"c_board":["Щит","Board"],"c_block":["Стальной блок","Steel block"],"c_corner":["Уголок","Corner"],"c_triangle":["Косынка","Gusset"],
	"c_pipe":["Труба","Pipe"],"c_frame":["Рама","Frame"],"c_platform":["Настил","Deck"],"c_counterweight":["Противовес","Counterweight"],
	"c_hinge":["Шарнир","Hinge"],"c_axle":["Ось с колесом","Axle wheel"],"c_motor":["Мотор","Motor"],"c_spring":["Амортизатор","Shock absorber"],
	"c_jet":["Ускоритель","Booster"],"c_balloon":["Подъёмный шар","Lift balloon"],"c_spikes":["Шипы","Spikes"],"c_wing":["Крыло","Wing"],
	"veh_wheel":["Колесо машины","Vehicle wheel"]
}
const ITEM_ABOUT = {
	# Why any of this is on the shelf: the passive toys are material samples —
	# each one isolates a single physical property so it can be compared against
	# the others — and the powered toys are bench apparatus that act on whatever
	# comes near. Every line below is read off the numbers in TOY_PHYS, so the
	# copy cannot drift away from what the object actually does.
	# Robots: prochnost, mass and the ability each variant runs in life mode.
	"robot":["Базовая модель: 100 прочности, роль — рабочий.","Baseline model: 100 integrity, works as a general hand."],
	"robot_scout":["Лёгкий и мелкий: 70 прочности, но вдвое легче обычного.","Light and small: 70 integrity at under two thirds the mass."],
	"robot_titan":["Тяжеловес: 280 прочности, почти вдвое тяжелее, видит цели за 520.","Heavyweight: 280 integrity, nearly double mass, spots targets at 520."],
	"robot_jumper":["Подпрыгивает каждые 1.55 с, пока стоит на опоре.","Springs upward every 1.55 s whenever it has footing."],
	"robot_magnet":["Тянет к себе всё в радиусе 270 — кроме дерева, стекла и шаров.","Draws everything within 270 — except wood, glass and balloons."],
	"robot_tesla":["Бьёт разрядом по ближайшему роботу в 260 каждые 0.7 с.","Arcs at the nearest robot within 260 every 0.7 s."],
	"robot_bomber":["Подкрадывается к цели и подрывает себя. 85 прочности.","Stalks a target and detonates itself. 85 integrity."],
	"robot_medic":["Чинит соседних роботов в радиусе 230, пока сам цел.","Repairs nearby robots within 230 while it still stands."],
	"robot_antigrav":["Гравитация действует на него втрое слабее — почти парит.","Gravity pulls on it at under a third — it nearly floats."],
	"robot_runner":["Бегает вдоль зала со скоростью 260 и разворачивается у края.","Runs the hall at 260 and turns around at the ends."],
	"robot_acrobat":["Делает сальто каждые 1.8 с, каждый раз меняя направление.","Flips every 1.8 s, reversing direction each time."],
	# Viruses: behaviour programs loaded into a robot.
	"virus_rage":["Гонится за ближайшим объектом и таранит его.","Chases the nearest object and rams it."],
	"virus_hunter":["Охота: ищет ближайшую цель и идёт на неё, как ярость.","Hunt: finds the nearest target and closes in, same as rage."],
	"virus_follow":["Держится в 70 от ближайшего робота — ходит за ним хвостом.","Holds 70 from the nearest robot and tails it everywhere."],
	"virus_panic":["Меняет направление каждые 0.55 с и мечется со скоростью 160.","Flips direction every 0.55 s and bolts at 160."],
	"virus_dance":["Раскачивает корпус и подпрыгивает каждые полсекунды.","Rocks its torso and hops every half second."],
	"virus_guard":["Расталкивает от себя всё, что подошло ближе 130.","Shoves away anything that comes within 130."],
	"virus_leap":["Прыжок строго вверх раз в 1.7 с, без всякой цели.","A straight jump every 1.7 s, aimed at nothing."],
	"virus_orbit":["Кружит вокруг ближайшего объекта, удерживая радиус 180.","Circles the nearest object, holding a radius of 180."],
	"virus_float":["Висит на высоте 400 и медленно качается из стороны в сторону.","Hovers at height 400, drifting slowly side to side."],
	"virus_spin":["Безостановочно крутит корпус вокруг своей оси.","Spins its torso without stopping."],
	# Parts: the plain building stock.
	"crate":["Ящик 46×46, 4 кг. Дешёвый строительный материал — и разлетается в щепки.","46×46 crate, 4 kg. Cheap building stock that bursts into splinters."],
	"barrel":["6 кг взрывчатки: от удара разносит всё в радиусе 230.","6 kg of explosive: a hard hit blows everything within 230."],
	"ball":["Шар 12 кг: катится и передаёт импульс дальше по цепочке.","12 kg ball: rolls and passes momentum down the line."],
	"plank":["Доска 130 см при 5 кг — балка для мостов и рычагов.","A 130-long plank at 5 kg: the beam for bridges and levers."],
	"metal":["Стальная плита 16 кг — прочная опора и хорошая мишень для магнита.","16 kg steel plate: a solid base, and magnets love it."],
	"glass":["2 кг и всего 22 прочности: бьётся почти от любого касания.","2 kg and just 22 integrity: it breaks at almost any touch."],
	"weight":["48 кг и 400 прочности — самый тяжёлый груз в наборе деталей.","48 kg and 400 integrity — the heaviest load in the parts bin."],
	# Gadgets: powered helpers.
	"thruster":["Двигатель: включи — и он толкает себя и груз вверх по своей оси.","Thruster: switch it on and it drives itself and its load along its axis."],
	"mine":["Мина: срабатывает от удара или по команде, радиус 230.","Mine: triggered by impact or on command, 230 radius."],
	"magnet":["Притягивает всё с 285 — кроме дерева, стекла и шаров.","Attracts anything within 285 — except wood, glass and balloons."],
	"fan":["Дует конусом на 360 вперёд — сдувает всё лёгкое.","Blows a cone 360 ahead and sweeps light things away."],
	"coil":["Катушка: разряд по ближайшему объекту в 250 каждые 0.55 с.","Coil: discharges at the nearest object within 250 every 0.55 s."],
	"sticky":["Клей: прилипает к первому, чего коснётся, и держит связку.","Glue: sticks to the first thing it touches and holds the bundle."],
	"trampoline":["Подбрасывает всё, что упало сверху, раз в треть секунды.","Launches whatever lands on it, three times a second at most."],
	"bumper":["Отскок 0.95: почти не гасит удар, отбрасывает обратно.","0.95 bounce: it barely absorbs a hit, it returns it."],
	"balloon":["0.7 кг и отрицательная тяжесть — тянет привязанное вверх.","0.7 kg with negative gravity: it lifts whatever you tie to it."],
	"wheel":["Ведущее колесо: включи — и оно крутится, таща конструкцию.","Drive wheel: switch it on and it spins, hauling the build along."],
	"drone":["Держит высоту 390 и курсирует по залу сам.","Holds altitude 390 and patrols the hall on its own."],
	"c4":["Пластид с радиодетонатором: липнет к поверхностям. Нажми C или активируй для подрыва.","Radio-detonated explosive: sticks to surfaces. Press C or activate to detonate."],
	"laser_cutter":["Непрерывный лазер: прожигает броню, отсекает конечности и воспламеняет взрывчатку.","Continuous laser: burns armor, severs limbs and ignites explosives."],
	"singularity":["Гравитационная воронка: притягивает и закручивает все объекты в мощный вихрь.","Gravitational singularity: draws and swirls all nearby objects into a crushing vortex."],
	"syringe_life":["Реанимирует павших роботов, восстанавливает 100% здоровья и нейтрализует кислоты.","Resurrects dead robots, restores full integrity, and neutralizes all toxins."],
	"syringe_acid":["Вводит едкую кислоту: разъедает металл, плавит соединения и отрывает конечности.","Injects corrosive acid: dissolves metal, weakens joints, and liquefies the robot."],
	"syringe_nitro":["Делает ядро нестабильным: робот мощно детонирует при сильном ударе или падении.","Makes the chassis explosive: the robot violently detonates upon heavy impact."],
	"syringe_overclock":["Разгоняет сервоприводы в 2.5 раза: суперскорость бега, прыжков и ударов.","Overclocks servos to 2.5x speed: hyper movement, leaping, and attack velocity."],
	"syringe_freeze":["Мгновенная крио-заморозка: превращает цель в скользящий ледяной блок.","Flash-freezes the subject into a zero-friction sliding crystalline block."],
	# Ballistic weapons: speed / force / rate straight from GUN_FIRE.
	"pistol":["Простой ствол: 1550 скорости, выстрел каждые 0.24 с.","Plain sidearm: 1550 speed, a shot every 0.24 s."],
	"revolver":["Тяжелее пистолета: больше урон и отдача, 0.36 с между выстрелами.","Heavier than the pistol: more punch and kick, 0.36 s between shots."],
	"rifle":["Самый точный ствол: разброс 0.012 и скорость 1950.","The most accurate barrel: 0.012 spread at 1950 speed."],
	"shotgun":["5 картечин за выстрел с разбросом 0.2 — в упор сносит всё.","Five pellets at 0.2 spread — devastating up close."],
	"sawed":["Обрез: 6 картечин, разброс 0.34, отдача 360 — бьёт и по стрелку.","Sawed-off: six pellets, 0.34 spread, 360 kick — it shoves the shooter too."],
	"nailgun":["Гвоздомёт: выстрел каждые 0.1 с, почти без отдачи.","Nailer: a shot every 0.1 s with almost no kick."],
	"grenade":["Граната: активируй и бросай, взрыв радиусом 190.","Grenade: arm it and throw, 190 blast radius."],
	"turret":["Турель: сама наводится и бьёт по всему в радиусе 420.","Turret: tracks and fires at anything within 420 on its own."],
	"flak":["Стреляет ЭМИ-зарядами — сбивает механизмы, а не ломает их.","Fires EMP charges: it disrupts machinery rather than shredding it."],
	# Exotic: mostly GUN_SPECIAL modes.
	"railgun":["Скорость 2400 и сила 72 — самый мощный выстрел, отдача 420.","2400 speed at 72 force: the hardest shot here, with 420 of kick."],
	"crossbow":["Тихий болт: разброс 0.01, перезарядка 0.66 с.","Quiet bolt: 0.01 spread, 0.66 s to reload."],
	"rocket_gun":["Медленная ракета 720 — летит на глазах и взрывается.","A slow 720 rocket: you watch it travel, then it detonates."],
	"flamer":["Струя огня очередями по 0.08 с — поджигает всё на пути.","A flame jet in 0.08 s bursts that sets the path alight."],
	"freezer":["Замораживает попадание: цель перестаёт двигаться.","Freezes what it hits: the target stops moving."],
	"tesla_gun":["Луч на 300: бьёт 18 урона каждые 0.34 с без снарядов.","A 300-range beam: 18 damage every 0.34 s, no ammo."],
	"harpoon":["Тяжёлый гарпун: 28 силы, пробивает и тащит за собой.","Heavy harpoon: 28 force, it punches through and drags."],
	"glue_gun":["Кидает липучки каждые 0.28 с — склеивает конструкции на лету.","Lobs glue every 0.28 s, sticking builds together mid-air."],
	"bouncer":["Рикошетящие заряды: летят дальше после каждого отскока.","Ricocheting rounds that keep going after every bounce."],
	"cannon":["Ядро 62 силы с отдачей 460 — стреляет раз в секунду.","A 62-force cannonball with 460 kick, once a second."],
	"minigun":["Выстрел каждые 0.07 с: слабые пули, но сплошным потоком.","A shot every 0.07 s: weak rounds, but a solid stream."],
	"pulse_gun":["Волна расталкивает всё вокруг — оружие без снарядов.","A wave that shoves everything nearby — no projectiles at all."],
	"grapple":["Крюк на тросе: притягивает цель или подтягивает стрелка.","A cable hook: it reels the target in, or the shooter to it."],
	"mine_gun":["Забрасывает мины по дуге — готовая ловушка на расстоянии.","Lobs mines in an arc: a ready-made trap at range."],
	"balloon_gun":["Стреляет шарами: цель поднимает в воздух, а не ломает.","Fires balloons: it lifts the target instead of breaking it."],
	"vortex":["Воронка стягивает всё вокруг точки попадания.","A vortex that drags everything toward the point of impact."],
	"disc_gun":["Пилящий диск: летит ровно и режет по пути.","A cutting disc: it flies flat and slices what it passes."],
	"taser":["Ближний луч на 95: 12 урона, обездвиживает вплотную.","A 95-range beam: 12 damage, for stopping things point-blank."],
	"cluster":["Один выстрел раз в 0.85 с распадается на пачку зарядов.","One shot every 0.85 s that splits into a handful of charges."],
	"wind_gun":["Поток воздуха очередями 0.12 с — сдувает, но не ломает.","An air blast every 0.12 s: it pushes without breaking."],
	# Melee: урон зависит от типа оружия (slash/crush/pierce/fast) и скорости удара.
	"sword":       ["Режущее: ~29 урона при обычном ударе, баланс скорости и силы.",      "Slash: ~29 damage on a typical swing — balanced speed and power."],
	"axe":         ["Режущее: ~40 урона, медленный замах — редко, но тяжело.",             "Slash: ~40 damage, slow swing — rare and crushing."],
	"spear":       ["Колющее: скорость решает — быстрый укол даёт до 35+ урона.",         "Pierce: speed matters — a fast thrust deals 35+ damage."],
	"hammer":      ["Дробящее: ~57 урона в базе — всегда бьёт тяжело, мало зависит от скорости.", "Crush: ~57 base damage — always hits hard, speed matters little."],
	"knife":       ["Колющее: ~24 урона, но быстрее всего — скорость усиливает укол.",    "Pierce: ~24 damage, fastest weapon — speed amplifies each stab."],
	"katana":      ["Режущее: ~28 урона при замахе 0.2 с — быстрый клинок с хорошим уроном.", "Slash: ~28 damage on a 0.2 s swing — fast, and it still hurts."],
	"scythe":      ["Режущее: ~37 урона по широкой дуге — бьёт несколько целей.",         "Slash: ~37 damage across a wide arc — hits multiple targets."],
	"mace":        ["Дробящее: ~45 урона и тяжёлый толчок — проламывает постройки.",      "Crush: ~45 damage with a heavy shove — caves structures in."],
	"chainsaw":    ["Пилит непрерывно, пока касается цели.",                               "Rev it and it cuts continuously while it touches the target."],
	"bat":         ["Дробящее: ~34 урона, зато отбрасывает сильнее всех — отправляет в полёт.", "Crush: ~34 damage but massive shove — sends things flying."],
	"whip":        ["Хлёсткое: лёгкий удар от скорости, длина 104 — достаёт далеко.",    "Fast: speed-driven light hit, length 104 — it reaches far."],
	"plasma_blade":["Режущее: ~38 урона при замахе 0.26 с — режет почти без сопротивления.", "Slash: ~38 damage on a 0.26 s swing — cuts with no resistance."],
	"crowbar":     ["Дробящее: ~32 урона и 160 прочности — инструмент, переживший всё.", "Crush: ~32 damage and 160 integrity — the tool that outlives everything."],
	"halberd":     ["Колющее: скорость решает, запас 350 толчка — бьёт с дистанции.",    "Pierce: speed matters, 350 shove — reach and thrust from a distance."],
	"hook":        ["Хлёсткое: цепляет и тащит цель за собой на 170.",                    "Fast: it catches the target and drags it 170."],
	"rubber":["Эталон упругости: отскок 0.96 — удар почти не теряет силу.","Elasticity sample: 0.96 bounce, it gives back nearly everything."],
	"ice":["Эталон скольжения: трение 0.04, разгоняется от любого толчка.","Low-friction sample: 0.04 grip, one nudge and it keeps going."],
	"soap":["Скользит ещё лучше льда и весит вдвое меньше.","Slipperier than ice and half the weight."],
	"sponge":["Гаситель: падает и замирает на месте, не катится.","Damper: lands and stops dead instead of rolling."],
	"anvil":["Эталон массы: 72 кг продавливают почти любую постройку.","Mass standard: 72 kg flattens most of what you build."],
	"feather":["Почти без веса: тяжесть действует на него втрое слабее.","Near-weightless: gravity pulls on it at a third strength."],
	"spring_block":["Пружинный блок: возвращает часть удара обратно вверх.","Spring block: returns part of an impact upward."],
	"pillow":["Поглотитель падения: гасит удар без отскока.","Impact absorber: kills a fall with no rebound."],
	"slime":["Липкая масса: трение 1.2, цепляется и тормозит соседей.","Sticky mass: 1.2 friction, it grabs and drags on neighbours."],
	"cork":["Легче воздуха — всплывает к потолку сам.","Lighter than air: it floats up to the ceiling on its own."],
	"brick":["Строительный блок: 18 кг и 180 прочности для стен и башен.","Building block: 18 kg, 180 health — walls and towers."],
	"crystal":["Хрупкий образец: 16 прочности, разлетается от щелчка.","Brittle sample: 16 health, it shatters at a tap."],
	"tire":["Катится и прыгает: сцепление 1.15 при отскоке 0.58.","Rolls and bounces: 1.15 grip with a 0.58 rebound."],
	"gyro":["Волчок: раскрути — вращение почти не затухает.","Top: spin it up and the rotation barely decays."],
	"dice":["Кубик для честной случайности: угадай, какой гранью ляжет.","A fair die: call which face it lands on."],
	"sandbag":["Мешок-упор: тяжёлый и полностью съедает удар.","Ballast bag: heavy, and it eats an impact whole."],
	"gel":["Упругий шар: мягче резины, прыгает почти так же.","Elastic ball: softer than rubber, bounces nearly as well."],
	"lead":["Самое плотное в лаборатории: 58 кг в маленьком кубике.","The densest thing here: 58 kg in a small cube."],
	"paper":["Ничего не весит и рвётся от любого касания.","Weighs nothing and tears at the slightest touch."],
	"honeycomb":["Лёгкая, но жёсткая структура — прочность почти даром.","Light yet stiff: strength for almost no mass."],
	"conveyor":["Лента: толкает всё, что на ней лежит, вдоль себя.","Belt: pushes whatever rests on it along its length."],
	"spinner_pad":["Раскручивает сам себя — опора для вращающихся связок.","Spins itself up — a hub for anything you link to it."],
	"updraft":["Восходящий поток: поднимает всё в радиусе 240.","Updraft: lifts everything within 240 of it."],
	"chiller":["Замораживает движение того, что его коснулось.","Chills the motion out of whatever touches it."],
	"vacuum_box":["Втягивает предметы к себе с расстояния 260.","Pulls objects toward itself from 260 away."],
	"shaker":["Непрерывно трясётся — проверка построек на вибрацию.","Vibrates nonstop — a shake test for your structures."],
	"pulsar":["Импульс во все стороны каждые 0.75 с.","Pulses outward in every direction every 0.75 s."],
	"lift":["Платформа-подъёмник: несёт груз вверх по своей оси.","Lift plate: carries a load up along its own axis."],
	"speaker":["Звуковая волна расталкивает всё вокруг толчками.","Sound wave: shoves everything around it in bursts."],
	"grav_well":["Колодец: давит всё в радиусе 240 вниз, к полу.","Well: presses everything within 240 down to the floor."],
	"hover_pad":["Отменяет вес того, что на нём стоит.","Cancels the weight of whatever stands on it."],
	"zapper":["Разряд гасит скорость коснувшегося почти до нуля.","A discharge cuts a toucher's speed to almost nothing."],
	"metronome":["Качается с постоянным ритмом — задаёт такт механизму.","Swings at a fixed rhythm — a clock for your mechanism."],
	"pump":["Толкает всё рядом строго в одну сторону, вдоль оси.","Drives everything nearby one way, along its axis."],
	"scatter_pad":["Разбрасывает соседей в случайные стороны дважды в секунду.","Flings neighbours in random directions twice a second."],
	"slow_field":["Тормозное поле: гасит скорость всего в радиусе 170.","Drag field: bleeds speed off everything within 170."],
	"boost_pad":["Разгонная плита: толкает вперёд то, что по ней едет.","Boost plate: accelerates whatever rides across it."],
	"rotator":["Закручивает всё вокруг себя в радиусе 160.","Spins up everything around it within 160."],
	"magnet_pad":["Тянет к себе всё с 285 — кроме дерева, стекла и шаров.","Pulls anything within 285 — except wood, glass and balloons."],
	"thump":["Самый сильный толчок в лаборатории — бьёт вдоль своей оси.","The hardest shove on the shelf, delivered along its axis."],
	"water_pool":["Вода: выталкивает по Архимеду, тормозит, гасит огонь и проводит ток. Дерево и лёд всплывают, металл тонет.","Water: Archimedes lift, heavy drag, puts fires out and carries current. Wood and ice float, metal sinks."],
	"oil_pool":["Масло: скользкое и горючее. Одной искры хватает, чтобы вся лужа вспыхнула.","Oil: slippery and flammable. One spark and the whole slick goes up."],
	"acid_pool":["Кислота: разъедает всё, что в неё попало, 26 урона в секунду.","Acid: eats away at anything inside it, 26 damage per second."],
	"gas_can":["Канистра с топливом: загорается мгновенно, от огня взрывается и поджигает всё вокруг.","Fuel can: catches instantly and bursts into a fireball that sets the room alight."],
	"battery":["Батарея: клавишей F подаёт ток. Ток идёт по металлу, воде, связям и роботам.","Battery: press F to energise. Current travels through metal, water, links and robots."],
	"cable":["Кабель: чистый проводник. Соедини им батарею с целью — или просто брось в лужу.","Cable: a pure conductor. Run it from the battery to a target, or just drop it in a puddle."],
	"firework":["Фейерверк: F — поджиг. Взлетает и рассыпается снопом искр, которые поджигают.","Firework: press F to light. It flies up and bursts into sparks that start fires."],
	"torch":["Факел: слабый удар, зато поджигает всё, до чего дотянется.","Torch: a light hit, but it sets fire to whatever it touches."],
	"extinguisher":["Огнетушитель: струя пены тушит пламя и мочит цель, чтобы та не загорелась снова.","Extinguisher: a foam jet kills flames and soaks the target so it will not relight."],
	"car_sedan":["Легковушка: 70 кг, подвеска на пружинах, до 680 в секунду. F — вперёд, назад, стоп. V — сигнал.","Sedan: 70 kg on sprung suspension, up to 680 per second. F cycles forward, reverse, stop. V honks the horn."],
	"car_pickup":["Пикап: 120 кг, открытый кузов возит ящики и роботов, до 540 в секунду. V — сброс груза.","Pickup: 120 kg with an open bed that carries crates and robots, up to 540 per second. V dumps the load."],
	"car_monster":["Монстр-трак: колёса вдвое больше, ход подвески 40, мотор ставит его на дыбы. V — прыжок.","Monster truck: wheels twice the size, 40 of suspension travel, enough torque to pull wheelies. V jumps."],
	"car_tank":["Танк: 260 кг на пяти катках, до 250 в секунду. На ходу бьёт из пушки по роботам впереди. V — выстрел.","Tank: 260 kg on five road wheels, up to 250 per second. While moving it shells robots ahead. V fires."],
	"car_sport":["Спорткар: 60 кг, до 980 в секунду — самый быстрый. Низкая посадка, короткий ход подвески. V — нитро.","Sports car: 60 kg, up to 980 per second — the fastest. Low stance, short suspension travel. V fires the nitro."],
	"car_bus":["Автобус: 320 кг и 290 в длину, до 420 в секунду. На плоской крыше можно возить роботов. V — сигнал.","Bus: 320 kg and 290 long, up to 420 per second. Robots can ride on its flat roof. V honks the horn."],
	"car_mixer":["Бетономешалка: 260 кг на трёх осях. На ходу барабан крутится. V — сигнал.","Cement mixer: 260 kg on three axles. The drum turns while it drives. V honks the horn."],
	"car_jeep":["Внедорожник: полный привод, крупные шины и ход подвески 30 — лезет по завалам. V — прыжок.","Off-roader: four-wheel drive, big tyres and 30 of suspension travel for climbing rubble. V jumps."],
	"car_ambulance":["Скорая: на ходу чинит роботов в радиусе 190 и поднимает павших. Мигалка и сирена. V — ремонт.","Ambulance: while driving it repairs robots within 190 and revives the fallen. Lights and siren. V repairs."],
	"car_fire":["Пожарная: на ходу бьёт пеной по горящему в радиусе 520. Лестница, три оси, сирена. V — залп пены.","Fire engine: while driving it foams anything burning within 520. Ladder, three axles, siren. V fires a foam volley."],
	"car_police":["Полиция: до 820 в секунду, оглушает робота впереди в радиусе 320. Мигалка и сирена. V — арест.","Police car: up to 820 per second, stuns a robot ahead within 320. Lights and siren. V arrests."],
	"car_dozer":["Бульдозер: 300 кг на гусенице, отвал сгребает всё перед собой. До 190 в секунду. V — толчок отвалом.","Bulldozer: 300 kg on tracks, its blade shoves everything ahead. Up to 190 per second. V shoves with the blade."],
	"car_tractor":["Трактор: огромные задние колёса и тяга, которой хватит утащить что угодно. До 270 в секунду. V — буксир.","Tractor: huge rear wheels and enough pull to drag anything. Up to 270 per second. V hitches a tow."],
	"car_moto":["Мотоцикл: 45 кг, ведущее заднее колесо, гироскоп держит его вертикально даже после трамплина. V — прыжок.","Motorcycle: 45 kg, rear-wheel drive, a gyro keeps it upright even after a jump. V jumps."],
	"car_atv":["Квадроцикл: 55 кг, мягкая подвеска и зубастые шины — прыгает по кочкам. V — прыжок.","ATV: 55 kg, soft suspension and knobbly tyres — it bounces over bumps. V jumps."],
	"car_kart":["Картинг: 30 кг, почти без подвески, до 760 в секунду. V — нитро.","Go-kart: 30 kg, barely any suspension, up to 760 per second. V fires the nitro."],
	"car_limo":["Лимузин: 280 в длину и тонированные окна. Мягко идёт до 620 в секунду. V — сигнал.","Limousine: 280 long with tinted windows. Glides up to 620 per second. V honks the horn."],
	"car_apc":["БТР: 240 кг на четырёх осях, пулемёт в башне очередями бьёт по роботам впереди. V — очередь.","APC: 240 kg on four axles, the turret gun fires bursts at robots ahead. V fires a burst."],
	"car_heli":["Вертолёт: F — висеть, вперёд, назад, посадка. Держит высоту 300 и летит до 340 в секунду. V — трос.","Helicopter: F cycles hover, forward, reverse, land. Holds 300 altitude and flies up to 340 per second. V lowers the winch."],
	"c_beam":["Балка 90: основа любой конструкции. «Связь» с другой деталью сваривает их намертво.","Beam, 90 long: the base of any build. Link it to another part to weld them solid."],
	"c_beam_long":["Длинная балка 200: мосты, стрелы кранов, шасси. Сваривается «Связью» или F.","Long beam, 200: bridges, crane jibs, chassis. Weld it with Link or F."],
	"c_girder":["Ферма 180: лёгкая решётка, 7 кг — жёсткая и почти ничего не весит.","Girder, 180: an open truss at 7 kg — stiff and nearly weightless."],
	"c_plate":["Стальной лист 100 на 50: борт, пол кабины или броня.","Steel plate, 100 by 50: a hull side, a cab floor or armour."],
	"c_board":["Деревянный щит: дёшево и сердито, но горит.","Wooden board: cheap and cheerful, but it burns."],
	"c_block":["Стальной блок 20 кг: узел, в который сходятся балки.","Steel block, 20 kg: a node where beams meet."],
	"c_corner":["Уголок: крепит балки под прямым углом.","Corner bracket: joins beams at a right angle."],
	"c_triangle":["Косынка: треугольник, который не даёт конструкции сложиться.","Gusset: a triangle that stops a frame from folding."],
	"c_pipe":["Труба 160: лёгкая, 3 кг — для мачт и ферм.","Pipe, 160: light at 3 kg — for masts and trusses."],
	"c_frame":["Рама 80 на 80: пустая внутри — лёгкий каркас для кабин и корпусов.","Frame, 80 by 80: hollow inside — a light skeleton for cabs and hulls."],
	"c_platform":["Настил 220: широкий и шершавый — груз на нём держится лучше, чем на гладкой балке.","Deck, 220: wide and gritty — cargo grips it better than a smooth beam."],
	"c_counterweight":["Противовес 80 кг: для кранов, качелей и таранов.","Counterweight, 80 kg: for cranes, see-saws and rams."],
	"c_hinge":["Шарнир: первой «Связью» крепится жёстко, следующие детали на нём вращаются. Двери, мосты, руки.","Hinge: the first Link mounts it solid, parts linked next swing on it. Doors, drawbridges, arms."],
	"c_axle":["Ось с колесом: всегда крепится с вращением. Четыре таких на раму — и готова тележка.","Axle wheel: always mounts free to spin. Four on a frame make a cart."],
	"c_motor":["Мотор: первой «Связью» — на основание, второй — к детали, которую крутить. F — по часовой, против, стоп.","Motor: first Link to the base, second to the part it turns. F cycles clockwise, counter, stop."],
	"c_spring":["Амортизатор: «Связь» с ним ставит жёсткую пружину с демпфером — подвеска для самоделок.","Shock absorber: a Link through it fits a stiff damped spring — suspension for your builds."],
	"c_jet":["Ускоритель: F — тяга 26000 вдоль корпуса. Приварите к тележке или к крылу.","Booster: F gives 26000 of thrust along its body. Weld it to a cart or a wing."],
	"c_balloon":["Подъёмный шар: тянет вверх около 25 кг. Лопается от удара.","Lift balloon: pulls up about 25 kg. Pops when hit."],
	"c_spikes":["Шипы: ранят всё, что налетит на них быстрее 70.","Spikes: hurt anything that hits them faster than 70."],
	"c_wing":["Крыло: плоскость в потоке. Под наклоном на ходу даёт подъём — с ускорителем получится планер.","Wing: a plate in the airflow. Angled at speed it lifts — add a booster for a glider."]
}
const GUN_FIRE = {
	"pistol":{"shot":"slug","speed":1550.0,"force":22.0,"kick":110.0,"wait":0.24,"spread":0.03,"n":1},
	"revolver":{"shot":"slug","speed":1680.0,"force":30.0,"kick":150.0,"wait":0.36,"spread":0.02,"n":1},
	"rifle":{"shot":"slug","speed":1950.0,"force":36.0,"kick":170.0,"wait":0.4,"spread":0.012,"n":1},
	"shotgun":{"shot":"slug","speed":1250.0,"force":14.0,"kick":280.0,"wait":0.72,"spread":0.2,"n":5},
	"sawed":{"shot":"slug","speed":980.0,"force":15.0,"kick":360.0,"wait":0.82,"spread":0.34,"n":6},
	"nailgun":{"shot":"nail","speed":1320.0,"force":12.0,"kick":40.0,"wait":0.1,"spread":0.04,"n":1},
	"flak":{"shot":"emp","speed":880.0,"force":20.0,"kick":95.0,"wait":0.48,"spread":0.015,"n":1},
	"railgun":{"shot":"slug","speed":2400.0,"force":72.0,"kick":420.0,"wait":0.85,"spread":0.004,"n":1},
	"crossbow":{"shot":"nail","speed":1100.0,"force":22.0,"kick":80.0,"wait":0.66,"spread":0.01,"n":1},
	"rocket_gun":{"shot":"rocket","speed":720.0,"force":40.0,"kick":220.0,"wait":0.8,"spread":0.02,"n":1},
	"harpoon":{"shot":"nail","speed":860.0,"force":28.0,"kick":130.0,"wait":0.7,"spread":0.015,"n":1},
	"freezer":{"shot":"chill","speed":980.0,"force":8.0,"kick":55.0,"wait":0.38,"spread":0.02,"n":1},
	"bouncer":{"shot":"bounce","speed":1280.0,"force":16.0,"kick":70.0,"wait":0.26,"spread":0.04,"n":1},
	"cannon":{"shot":"cannonball","speed":620.0,"force":62.0,"kick":460.0,"wait":1.05,"spread":0.01,"n":1},
	"minigun":{"shot":"slug","speed":1600.0,"force":9.0,"kick":28.0,"wait":0.07,"spread":0.09,"n":1},
	"disc_gun":{"shot":"disc","speed":1040.0,"force":24.0,"kick":95.0,"wait":0.44,"spread":0.03,"n":1}
}
const GUN_SPECIAL = {
	"flamer":{"mode":"flame","wait":0.08},
	"tesla_gun":{"mode":"beam","wait":0.34,"range":300.0,"hurt":18.0},
	"taser":{"mode":"beam","wait":0.4,"range":95.0,"hurt":12.0},
	"pulse_gun":{"mode":"wave","wait":0.52},
	"vortex":{"mode":"vortex","wait":0.7},
	"wind_gun":{"mode":"wind","wait":0.12},
	"grapple":{"mode":"grapple","wait":0.55},
	"cluster":{"mode":"cluster","wait":0.85},
	"mine_gun":{"mode":"lob","spawn":"mine","wait":0.7,"speed":520.0},
	"balloon_gun":{"mode":"lob","spawn":"balloon","wait":0.35,"speed":380.0},
	"glue_gun":{"mode":"lob","spawn":"sticky","wait":0.28,"speed":640.0},
	"extinguisher":{"mode":"foam","wait":0.09}
}
const MELEE_STATS = {
	# type: "slash"=режущее, "crush"=дробящее, "pierce"=колющее, "fast"=быстрое/хлёсткое
	"sword":       {"wait":0.22,"spin":170.0,"shove":240.0,"hit":36.0,"type":"slash"},
	"axe":         {"wait":0.30,"spin":220.0,"shove":320.0,"hit":54.0,"type":"slash"},
	"spear":       {"wait":0.25,"spin":40.0, "shove":340.0,"hit":46.0,"type":"pierce","thrust":1.0},
	"hammer":      {"wait":0.36,"spin":220.0,"shove":460.0,"hit":75.0,"type":"crush"},
	"knife":       {"wait":0.12,"spin":110.0,"shove":120.0,"hit":20.0,"type":"pierce"},
	"katana":      {"wait":0.16,"spin":210.0,"shove":200.0,"hit":34.0,"type":"slash"},
	"scythe":      {"wait":0.32,"spin":240.0,"shove":260.0,"hit":46.0,"type":"slash"},
	"mace":        {"wait":0.30,"spin":190.0,"shove":380.0,"hit":56.0,"type":"crush"},
	"bat":         {"wait":0.24,"spin":180.0,"shove":360.0,"hit":38.0,"type":"crush"},
	"whip":        {"wait":0.20,"spin":220.0,"shove":140.0,"hit":22.0,"type":"fast"},
	"plasma_blade":{"wait":0.20,"spin":180.0,"shove":250.0,"hit":48.0,"type":"slash"},
	"crowbar":     {"wait":0.24,"spin":150.0,"shove":280.0,"hit":36.0,"type":"crush"},
	"halberd":     {"wait":0.30,"spin":90.0, "shove":350.0,"hit":50.0,"type":"pierce","thrust":1.0},
	"hook":        {"wait":0.24,"spin":130.0,"shove":240.0,"hit":30.0,"type":"fast"},
	"torch":       {"wait":0.28,"spin":150.0,"shove":150.0,"hit":14.0,"type":"fast"}
}
const SCENES = [
	["sandbox","Песочница","Sandbox","Полная свобода действий","A space for your imagination","robot","lab"],
	["tower","Башня","Tower","Испытай конструкцию","Put a structure to the test","crate","lab"],
	["chain","Цепная реакция","Chain reaction","Один импульс. Семь взрывов.","One pulse. Seven explosions.","barrel","lab"],
	["flight","Полёт","Flight","Собери летающую платформу","Build a flying platform","thruster","lab"],
	["rink","Каток","Rink","Скользи и сталкивайся","Slide and collide","ice","ice"],
	["factory","Цех","Factory","Конвейер несёт ящики","The belt carries crates","conveyor","factory"],
	["park","Парк","Park","Лёгкие вещи и батут","Light things and a trampoline","balloon","park"],
	["range","Тир","Range","Мишени из ящиков","Crate targets","pistol","range"],
	["flood","Затопление","Flood","Вода, масло и одна искра","Water, oil and a single spark","water_pool","lab"],
	["circuit","Цепь","Circuit","Батарея, кабель и лужа","A battery, a cable and a puddle","battery","factory"],
	["maglab","Магнитный зал","Magnet hall","Металл сам идёт к магнитам","Metal finds the magnets","magnet","magnet"],
	["storm","Шторм","Storm","Ветер подхватывает всё лёгкое","Wind lifts anything light","fan","storm"],
	["bounce","Батут-зал","Bounce hall","Прыгай и отскакивай","Jump and rebound","trampoline","bounce"],
	["neon","Неон","Neon","Импульсы и разряды","Pulses and sparks","zapper","neon"],
	["quarry","Карьер","Quarry","Тяжёлые грузы и кристалл","Heavy loads and crystal","anvil","quarry"],
	["skydock","Причал","Sky dock","Пари над площадкой","Hover over the pad","hover_pad","sky"],
	["dojo","Додзё","Dojo","Два бойца и клинки","Two fighters and blades","sword","dojo"],
	["foundry","Литейная","Foundry","Наковальня падает на металл","An anvil drops on metal","anvil","foundry"],
	["pinball","Пинбол","Pinball","Шары, бамперы, ускорители","Balls, bumpers, boosts","bumper","arcade"],
	["void","Бездна","Void","Колодец тянет всё внутрь","The well pulls everything in","grav_well","void"],
	["span","Мост","Span","Стеклянный мост не прощает","The glass bridge does not forgive","glass","canyon"],
	["clockwork","Часовая","Clockwork","Шестерни уже крутятся","The gears are already turning","metronome","brass"],
	["bath","Баня","Bath","Мыло, слизь и ни капли трения","Soap, slime and no friction","soap","bath"],
	["reef","Риф","Reef","Пробки всплывают, насос качает","Corks rise, the pump works","cork","reef"],
	["junkyard","Свалка","Junkyard","Шины, лом и колёса","Tires, a crowbar and wheels","tire","rust"],
	["relay","Трасса","Relay","Разгон по плитам","Boost along the pads","boost_pad","track"]
]
const TOOLS = ["grab","pulse","blast","freeze","link","delete","pan"]
const GOALS = [
	["spawn",5,"Первые открытия","First discoveries"],
	["pulse",12,"Испытание импульсом","Pulse test"],
	["freeze",4,"Время остановиться","Frozen in time"],
	["link",3,"Всё связано","Making connections"],
	["crate",6,"Проверка на прочность","Stress test"],
	["explosion",8,"Цепная реакция","Chain reaction"],
	["launch",4,"Выше и выше","Sky is the limit"],
	["spawn",60,"Главный инженер","Chief engineer"],
	["fire",6,"Пожарная тревога","Fire drill"],
	["shock",6,"Под напряжением","Live wire"],
	["splash",5,"Глубокая вода","Deep water"]
]

var arena: LabArena
var world: Node2D
var fx: LabEffects
var ambience: Node2D
var overlay: Node2D
var camera: Camera2D
var hud: Control
var platform: LabPlatform
var selected: LabBody
var dragging: LabBody
var link_first: LabBody
# Сварка конструктора: {a, b, type, joints}. См. parts.gd.
var welds: Array=[]
var drag_offset=Vector2.ZERO
var links: Array[Dictionary]=[]
var tool="grab"
var spawn_kind="robot"
var placing=false
var placing_rotation: float = 0.0
var user_paused=false
var menu_open=true
var help_open=false
var slow=false
var gravity=true
var muted=false
var mobile=false
var catalog_open=true
var catalog_category=0
var catalog_page=0
var pending_scene=""
var lang="ru"
var lang_override=""
var scene_name="sandbox"
var menu_scene_page=0
var counter=0
var camera_center=Vector2(640,400)
var camera_shake=0.0
var cursor=Vector2.ZERO
var mouse_down=false
var panning=false
var fire_timer=0.0
var autosave_timer=0.0
var elapsed=0.0
var toast=""
var toast_time=0.0
var stats: Dictionary={}
var completed: Array=[]
var cached_scene: Dictionary={}
var audio: Dictionary={}
var audio_pool: Array[AudioStreamPlayer]=[]
var audio_index=0
var test_mode=false
var post_material: ShaderMaterial
var impact_flash: float = 0.0

func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	platform=LabPlatform.new()
	add_child(platform)
	platform.state_changed.connect(_platform_changed)
	platform.ad_finished.connect(_finish_scene_change)
	mobile=platform.mobile or "--mobile-test" in OS.get_cmdline_user_args()
	if mobile:
		get_tree().root.content_scale_size=Vector2i(854,480)
		catalog_open=false
	lang=platform.language
	var data=platform.load_data()
	stats=data.get("stats",{}) if data.get("stats",{}) is Dictionary else {}
	completed=data.get("completed",[]) if data.get("completed",[]) is Array else []
	muted=bool(data.get("muted",false))
	cached_scene=data.get("scene",{}) if data.get("scene",{}) is Dictionary else {}
	lang_override=str(data.get("lang",""))
	_apply_language()
	world=Node2D.new()
	world.process_mode=Node.PROCESS_MODE_PAUSABLE
	add_child(world)
	arena=LabArena.new()
	# Лужи рисуются на z_index -2, под телами; непрозрачный фон должен быть
	# ещё ниже, иначе он полностью закрывает воду, масло и кислоту.
	arena.z_index=-10
	world.add_child(arena)
	ambience=load("res://scripts/ambience.gd").new()
	ambience.game=self
	world.add_child(ambience)
	fx=LabEffects.new()
	fx.z_index=10
	world.add_child(fx)
	# Links and cursor hints have to live inside `world`. Drawing them on the
	# main node put them underneath the arena, which paints an opaque
	# background after its parent and hid every one of them.
	overlay=Node2D.new()
	overlay.z_index=20
	overlay.draw.connect(_draw_overlay)
	world.add_child(overlay)
	camera=Camera2D.new()
	camera.position=camera_center
	add_child(camera)
	_add_post_processing()
	var layer=CanvasLayer.new()
	layer.layer=10
	add_child(layer)
	hud=load("res://scripts/hud.gd").new()
	hud.game=self
	layer.add_child(hud)
	_make_audio()
	build_scene("sandbox")
	_update_pause()
	await get_tree().process_frame
	platform.ready_for_player()
	if "--smoke-test" in OS.get_cmdline_user_args():
		test_mode=true
		_run_smoke_test.call_deferred()
	elif "--visual-test" in OS.get_cmdline_user_args():
		test_mode=true
		menu_open=false
		_update_pause()
		_visual_test.call_deferred()
	elif "--visual-mobile" in OS.get_cmdline_user_args():
		test_mode=true
		menu_open=false
		_update_pause()
		_visual_mobile.call_deferred()
	elif "--visual-damage" in OS.get_cmdline_user_args():
		test_mode=true
		menu_open=false
		_update_pause()
		_visual_damage.call_deferred()
	elif "--visual-toys" in OS.get_cmdline_user_args():
		test_mode=true
		menu_open=false
		catalog_category=4
		_update_pause()
		_visual_toys.call_deferred()
	elif "--visual-scenes" in OS.get_cmdline_user_args():
		test_mode=true
		menu_open=false
		_update_pause()
		_visual_scenes.call_deferred()
	elif "--visual-vehicles" in OS.get_cmdline_user_args():
		test_mode=true
		menu_open=false
		_update_pause()
		_visual_vehicles.call_deferred()
	elif "--visual-items" in OS.get_cmdline_user_args():
		test_mode=true
		menu_open=false
		catalog_category=3
		_update_pause()
		_visual_test.call_deferred()

func _add_post_processing() -> void:
	pass

func catalog_items() -> Array:
	return CATALOG[clampi(catalog_category,0,CATALOG.size()-1)][3]

func catalog_page_size() -> int:
	return 6 if mobile else 12

func can_hold(kind: String) -> bool:
	return (kind in WEAPONS or kind in EXOTIC or kind in MELEE) and kind!="turret"

func t(ru: String, en: String) -> String:
	return ru if lang=="ru" else en

func _apply_language() -> void:
	# A player choice outranks the locale reported by the portal or the browser.
	lang=lang_override if lang_override in ["ru","en"] else platform.language

func toggle_language() -> void:
	lang_override="en" if lang=="ru" else "ru"
	_apply_language()
	platform.set_page_language(lang)
	save_progress()
	notify(t("Язык интерфейса: русский","Interface language: English"))

func next_id() -> int:
	counter+=1
	return counter

func _platform_changed() -> void:
	if not is_instance_valid(world): return
	_apply_language()
	if platform.suspended:
		release_drag()
		if not menu_open: save_snapshot(false)
	_update_pause()

func _update_pause() -> void:
	var paused=user_paused or menu_open or help_open or platform.suspended or not pending_scene.is_empty()
	get_tree().paused=paused
	AudioServer.set_bus_mute(0,muted or paused)
	platform.gameplay(not paused)
	Engine.time_scale=0.25 if slow else 1.0

func _process(delta: float) -> void:
	var real_delta=delta/Engine.time_scale
	toast_time=maxf(0,toast_time-real_delta)
	cursor=get_global_mouse_position()
	fire_timer=maxf(0,fire_timer-delta)
	if not get_tree().paused:
		elapsed+=real_delta
		autosave_timer+=real_delta
		if autosave_timer>8:
			autosave_timer=0
			save_snapshot(false)
		if mouse_down and tool=="pulse" and not placing and not hud.blocks(get_viewport().get_mouse_position()) and fire_timer<=0:
			pulse(cursor)
	if is_instance_valid(dragging) and user_paused and not menu_open:
		var shift=cursor-dragging.to_global(drag_offset)
		if is_instance_valid(dragging.ragdoll):
			for b in dragging.ragdoll.connected_parts(dragging.part_index): b.global_position+=shift
		else:
			for b in LabVehicle.bodies(dragging): b.global_position+=shift
	if not menu_open and not help_open and not platform.suspended:
		var cam_move = Vector2.ZERO
		if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W): cam_move.y -= 1.0
		if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S): cam_move.y += 1.0
		if Input.is_key_pressed(KEY_LEFT) or (Input.is_key_pressed(KEY_A) and not is_instance_valid(selected)): cam_move.x -= 1.0
		if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D): cam_move.x += 1.0
		if cam_move != Vector2.ZERO:
			var cam_speed = (920.0 / camera.zoom.x) * real_delta
			if Input.is_key_pressed(KEY_SHIFT): cam_speed *= 2.2
			camera_center += cam_move.normalized() * cam_speed
			camera_center.x = clampf(camera_center.x, -1600, 3900)
			camera_center.y = clampf(camera_center.y, -1000, 800)
	camera_shake=move_toward(camera_shake,0,real_delta*24)
	camera.position=camera_center+Vector2(randf_range(-1,1),randf_range(-1,1))*camera_shake
	impact_flash=move_toward(impact_flash,0.0,real_delta*4.2)
	if is_instance_valid(post_material): post_material.set_shader_parameter("impact_flash",impact_flash)
	if is_instance_valid(overlay): overlay.queue_redraw()
	if is_instance_valid(hud): hud.queue_redraw()

func _physics_process(_delta: float) -> void:
	if get_tree().paused: return
	if is_instance_valid(dragging) and dragging.kind in FLUIDS:
		# Лужа заморожена и без коллизии, силой её не подвинуть — ведём прямо
		# за курсором, иначе инструмент "Захват" на ней просто не работает.
		dragging.global_position=cursor-drag_offset.rotated(dragging.rotation)
	elif is_instance_valid(dragging) and not dragging.freeze:
		var at=dragging.to_global(drag_offset)
		var force=((cursor-at)*65-dragging.linear_velocity*8)*dragging.mass
		dragging.apply_force(force.limit_length(70000),at-dragging.global_position)
		dragging.angular_velocity*=0.93
		if dragging.is_attached_robot_part():
			dragging.ragdoll.stun=0.4
			if dragging.ragdoll.dead: dragging.ragdoll.wake_for(0.25)
	for i in range(links.size()-1,-1,-1):
		var link=links[i]
		if not is_instance_valid(link.a) or not is_instance_valid(link.b):
			if is_instance_valid(link.joint): link.joint.queue_free()
			links.remove_at(i)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if platform.suspended: return
		match event.physical_keycode:
			KEY_ESCAPE:
				if help_open: help_open=false
				elif placing: placing=false; tool="grab"
				else: menu_open=not menu_open; save_snapshot(false)
				_update_pause()
			KEY_SPACE:
				if not menu_open: action("pause")
			KEY_1,KEY_2,KEY_3,KEY_4,KEY_5,KEY_6,KEY_7:
				if not menu_open: action("tool:"+TOOLS[event.physical_keycode-KEY_1])
			KEY_F:
				if not menu_open: activate_selected()
			KEY_A:
				if not menu_open: toggle_selected_autonomy()
			KEY_V:
				if not menu_open: use_vehicle_ability()
			KEY_DELETE,KEY_BACKSPACE:
				if not menu_open:
					if event.shift_pressed:
						action("clear_scene")
					elif is_instance_valid(selected):
						remove_entity(selected)
			KEY_D:
				if not menu_open and event.ctrl_pressed:
					duplicate_selected()
			KEY_Z:
				if not menu_open and event.ctrl_pressed:
					action("load")
			KEY_Q:
				if not menu_open:
					if placing: placing_rotation -= PI/12.0
					else: rotate_selected(-PI/12.0)
			KEY_E:
				if not menu_open:
					if placing: placing_rotation += PI/12.0
					else: rotate_selected(PI/12.0)
			KEY_R:
				if not menu_open: reset_view()
			KEY_TAB:
				if not menu_open: catalog_open=not catalog_open
			KEY_T:
				if not menu_open: action("slow")
			KEY_G:
				if not menu_open: action("gravity")
			KEY_C:
				if not menu_open: detonate_all_c4()
			KEY_M: action("mute")
			KEY_H: action("help")
			_: return
		get_viewport().set_input_as_handled()
	if event is InputEventMouseButton:
		var screen=event.position
		if event.button_index==MOUSE_BUTTON_LEFT and not event.pressed:
			mouse_down=false
			panning=false
			release_drag()
			return
		if event.button_index in [MOUSE_BUTTON_RIGHT,MOUSE_BUTTON_MIDDLE] and not event.pressed:
			panning=false
			return
		if not event.pressed: return
		if event.button_index==MOUSE_BUTTON_LEFT and hud.handle_click(screen): return
		if menu_open or help_open or platform.suspended or not pending_scene.is_empty(): return
		if hud.blocks(screen): return
		cursor=get_global_mouse_position()
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			zoom_at(1.12 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1/1.12)
		elif event.button_index in [MOUSE_BUTTON_RIGHT,MOUSE_BUTTON_MIDDLE]:
			if placing:
				placing=false
				tool="grab"
				notify(t("Размещение отменено","Placement cancelled"))
			else:
				panning=true
		elif event.button_index==MOUSE_BUTTON_LEFT:
			mouse_down=true
			if placing:
				spawn_item(spawn_kind,cursor,true,placing_rotation)
				if mobile: placing=false; tool="grab"
				return
			var body=pick(cursor)
			select(body)
			match tool:
				"grab":
					if is_instance_valid(body):
						if can_hold(body.kind) and is_instance_valid(body.holder):
							body.holder.drop_gun()
						dragging=body
						drag_offset=body.to_local(cursor)
						play_sound("grab",0.22)
					else: panning=true
				"pulse": pulse(cursor)
				"blast": explode(cursor,220,1)
				"freeze": freeze_selected()
				"delete":
					if body:
						remove_entity(body)
						play_sound("delete",0.34)
				"link":
					if body:
						if is_instance_valid(link_first) and link_first!=body:
							# С деталью конструктора «Связь» не пружинит, а сваривает.
							if LabParts.can_weld(self,link_first,body):
								if not LabParts.weld(self,link_first,body,"",true): notify(t("Эти детали уже соединены","These parts are already joined"))
							else: make_link(link_first,body,true)
							link_first=null
						else:
							link_first=body
							notify(t("Теперь выбери второй объект","Now select another object"))
				"pan": panning=true
	if event is InputEventMouseMotion and panning:
		camera_center-=event.relative/camera.zoom
		camera_center.x=clampf(camera_center.x,-1600,3900)
		camera_center.y=clampf(camera_center.y,-1000,800)

func action(id: String) -> void:
	if platform.suspended: return
	play_sound("click",0.2)
	if id.begins_with("item:"):
		spawn_kind=id.trim_prefix("item:")
		placing=true
		placing_rotation=0.0
		link_first=null
		if mobile: catalog_open=false
		return
	if id=="equip":
		try_equip_selected()
		return
	if id=="drop_gun":
		drop_selected_gun()
		return
	if id.begins_with("gear:"):
		set_selected_gear(int(id.trim_prefix("gear:")))
		return
	if id=="vehicle_ability":
		use_vehicle_ability()
		return
	if id=="scene_page_prev":
		menu_scene_page=maxi(0,menu_scene_page-1)
		return
	if id=="scene_page_next":
		var per=4 if mobile else 6
		menu_scene_page=mini((SCENES.size()-1)/per,menu_scene_page+1)
		return
	if id=="purge_virus":
		if is_instance_valid(selected) and is_instance_valid(selected.ragdoll) and selected.ragdoll.virus!="":
			selected.ragdoll.purge_virus()
			notify(t("Поведение сброшено","Behavior cleared"))
		return
	if id.begins_with("catalog_cat:"):
		catalog_category=clampi(int(id.trim_prefix("catalog_cat:")),0,CATALOG.size()-1)
		catalog_page=0
		return
	if id=="catalog_prev":
		catalog_page=maxi(0,catalog_page-1)
		return
	if id=="catalog_next":
		var items=catalog_items()
		var page_size=catalog_page_size()
		catalog_page=mini((items.size()-1)/page_size,catalog_page+1)
		return
	if id.begins_with("tool:"):
		tool=id.trim_prefix("tool:")
		placing=false
		link_first=null
		return
	if id.begins_with("scene:"):
		pending_scene=id.trim_prefix("scene:")
		if elapsed>45:
			save_snapshot(false)
			_update_pause()
			platform.show_ad()
		else: _finish_scene_change()
		return
	match id:
		"play":
			if not cached_scene.is_empty(): restore_snapshot(cached_scene)
			menu_open=false
			platform.request_fullscreen()
			_update_pause()
		"resume": menu_open=false; _update_pause()
		"menu": save_snapshot(false); menu_open=true; release_drag(); _update_pause()
		"pause": user_paused=not user_paused; release_drag(); _update_pause()
		"slow": slow=not slow; _update_pause()
		"gravity":
			gravity=not gravity
			for b in get_tree().get_nodes_in_group("bodies"):
				b.gravity_scale=0.0 if is_instance_valid(b.holder) else (b.gravity_factor if gravity else 0.0)
		"mute": muted=not muted; _update_pause(); save_progress()
		"lang": toggle_language()
		"help": help_open=not help_open; _update_pause()
		"catalog": catalog_open=not catalog_open
		"save": save_snapshot(true)
		"load":
			if not cached_scene.is_empty(): restore_snapshot(cached_scene); notify(t("Сцена восстановлена","Scene restored"))
		"activate": activate_selected()
		"freeze": freeze_selected()
		"rotate": rotate_selected(PI/4)
		"delete":
			if is_instance_valid(selected): remove_entity(selected)
		"clear_scene":
			save_snapshot(false)
			clear_scene()
			notify(t("Сцена очищена","Scene cleared"))
		"clone": duplicate_selected()
		"zoom_in": zoom_at(1.2)
		"zoom_out": zoom_at(1/1.2)
		"reset_view": reset_view()

func duplicate_selected() -> void:
	if not is_instance_valid(selected):
		notify(t("Сначала выбери объект для клонирования","Select an object to clone first"))
		return
	# Машина клонируется целиком, даже если выбрано её колесо, и встаёт рядом:
	# со сдвигом 70 новый кузов оказывался внутри старого.
	var car = LabVehicle.root(selected)
	var needed = 11 if is_instance_valid(selected.ragdoll) else (LabVehicle.part_count(car.kind) if car else 1)
	if get_tree().get_nodes_in_group("bodies").size() + needed > MAX_BODIES:
		notify(t("Лаборатория заполнена","Lab is full"))
		return
	var entity = selected.ragdoll if is_instance_valid(selected.ragdoll) else (car if car else selected)
	var offset = Vector2(float(car.dimensions.x) + 30.0, -20) if car else Vector2(70, -20)
	var spawn_pos = entity.global_position + offset
	if entity is LabRobot:
		var clone = spawn_item(entity.variant, spawn_pos, true)
		if clone:
			clone.tint = entity.tint
			for p in clone.parts:
				p.tint = clone.tint
				p.queue_redraw()
			if is_instance_valid(entity.held_gun):
				var gun_clone = spawn_item(entity.held_gun.kind, spawn_pos + Vector2(20, 0))
				if gun_clone:
					clone.equip_gun(gun_clone)
			if entity.virus != "":
				var chip = spawn_item(entity.virus, spawn_pos)
				if chip: infect_robot(clone, chip)
			select(clone.parts[1])
			notify(t("Робот продублирован","Robot duplicated"))
	elif entity is LabBody:
		var clone = spawn_item(entity.kind, spawn_pos, true, entity.rotation)
		if clone:
			clone.tint = entity.tint
			clone.dimensions = entity.dimensions
			clone.mass = entity.mass
			clone.health = entity.health
			clone.freeze = entity.freeze
			clone.active = entity.active
			if car:
				# Колёса — отдельные тела: заморозку они берут от кузова в rebuild.
				clone.gear = entity.gear
				clone.wrecked = entity.wrecked
				LabVehicle.rebuild(self, clone)
			select(clone)
			notify(t("Объект продублирован","Object duplicated"))
	play_sound("spawn", 0.4)

func detonate_all_c4() -> void:
	var c4_list: Array[LabBody] = []
	for b in get_tree().get_nodes_in_group("bodies"):
		if is_instance_valid(b) and b.kind == "c4":
			c4_list.append(b)
	if c4_list.is_empty(): return
	for b in c4_list:
		if is_instance_valid(b):
			b.detonate()
	notify(t("Детонация C4!","C4 detonated!"))

func _finish_scene_change() -> void:
	if pending_scene.is_empty(): return
	build_scene(pending_scene)
	pending_scene=""
	menu_open=false
	user_paused=false
	elapsed=0
	platform.request_fullscreen()
	_update_pause()
	save_snapshot(false)

func scene_theme(preset: String) -> String:
	for s in SCENES:
		if s[0]==preset: return str(s[6])
	return "lab"

func scene_title() -> String:
	for s in SCENES:
		if s[0]==scene_name: return t(str(s[1]),str(s[2]))
	return t("Свободный эксперимент","Free experiment")

func build_scene(preset: String) -> void:
	clear_scene()
	scene_name=preset
	if is_instance_valid(arena): arena.set_theme(scene_theme(preset))
	reset_view()
	match preset:
		"sandbox":
			spawn_item("robot",Vector2(590,FLOOR_Y-4))
			var second=spawn_item("robot",Vector2(730,FLOOR_Y-4))
			second.tint=Color("e8b56e")
			for b in second.parts: b.tint=second.tint; b.queue_redraw()
			spawn_item("crate",Vector2(900,594))
			spawn_item("crate",Vector2(950,594))
			spawn_item("crate",Vector2(925,543))
			spawn_item("barrel",Vector2(1080,590))
			spawn_item("ball",Vector2(420,593))
		"flood":
			# Бассейн по центру, над ним мостик из досок, слева масляная лужа
			# с канистрой, справа — то, что должно всплыть.
			spawn_item("water_pool",Vector2(760,FLOOR_Y-60))
			spawn_item("plank",Vector2(760,FLOOR_Y-135))
			spawn_item("cork",Vector2(700,FLOOR_Y-170))
			spawn_item("ice",Vector2(760,FLOOR_Y-180))
			spawn_item("anvil",Vector2(820,FLOOR_Y-190))
			spawn_item("oil_pool",Vector2(400,FLOOR_Y-35))
			spawn_item("gas_can",Vector2(360,FLOOR_Y-30))
			spawn_item("crate",Vector2(450,FLOOR_Y-26))
			spawn_item("crate",Vector2(496,FLOOR_Y-26))
			spawn_item("torch",Vector2(300,FLOOR_Y-20))
			spawn_item("extinguisher",Vector2(1080,FLOOR_Y-26))
			spawn_item("robot",Vector2(1000,FLOOR_Y-4))
		"circuit":
			# Батарея питает кабель, кабель уходит в воду, в воде стоит робот.
			var battery=spawn_item("battery",Vector2(380,FLOOR_Y-18))
			var wire_a=spawn_item("cable",Vector2(500,FLOOR_Y-14))
			var wire_b=spawn_item("cable",Vector2(620,FLOOR_Y-14))
			spawn_item("water_pool",Vector2(820,FLOOR_Y-45))
			spawn_item("robot",Vector2(820,FLOOR_Y-4))
			spawn_item("metal",Vector2(700,FLOOR_Y-22))
			spawn_item("rubber",Vector2(960,FLOOR_Y-24))
			spawn_item("cable",Vector2(740,FLOOR_Y-14))
			if battery and wire_a and wire_b:
				make_link(battery,wire_a)
				make_link(wire_a,wire_b)
		"tower":
			for y in range(6):
				for x in range(3): spawn_item("crate",Vector2(700+x*50,FLOOR_Y-25-y*50))
			spawn_item("robot",Vector2(990,FLOOR_Y-5))
			spawn_item("ball",Vector2(440,300))
			spawn_item("barrel",Vector2(640,590))
		"chain":
			for i in range(7): spawn_item("barrel",Vector2(420+i*108,590))
			for i in range(3): spawn_item("crate",Vector2(680+i*50,510))
			spawn_item("robot",Vector2(1170,615))
		"flight":
			var plank=spawn_item("plank",Vector2(750,450))
			var a=spawn_item("thruster",Vector2(700,505))
			var b=spawn_item("thruster",Vector2(800,505))
			make_link(plank,a)
			make_link(plank,b)
			spawn_item("robot",Vector2(750,437))
		"rink":
			spawn_item("robot",Vector2(620,FLOOR_Y-4))
			for i in range(4): spawn_item("ice",Vector2(380+i*90,607))
			spawn_item("soap",Vector2(900,609))
			spawn_item("ball",Vector2(480,593))
			spawn_item("rubber",Vector2(1040,598))
		"factory":
			var belt=spawn_item("conveyor",Vector2(760,612))
			if belt: belt.active=true
			spawn_item("crate",Vector2(680,581))
			spawn_item("crate",Vector2(760,581))
			spawn_item("crate",Vector2(840,581))
			var spin=spawn_item("spinner_pad",Vector2(1080,594))
			if spin: spin.active=true
			spawn_item("robot",Vector2(480,FLOOR_Y-4))
		"park":
			spawn_item("robot",Vector2(560,FLOOR_Y-4))
			spawn_item("balloon",Vector2(420,500))
			spawn_item("balloon",Vector2(700,460))
			spawn_item("cork",Vector2(820,593))
			spawn_item("feather",Vector2(900,400))
			spawn_item("trampoline",Vector2(1040,612))
		"range":
			spawn_item("robot",Vector2(420,FLOOR_Y-4))
			spawn_item("pistol",Vector2(500,610))
			for i in range(5): spawn_item("crate",Vector2(780+i*70,594))
			spawn_item("rubber",Vector2(620,598))
		"maglab":
			spawn_item("robot_magnet",Vector2(520,FLOOR_Y-4))
			var mag=spawn_item("magnet",Vector2(820,590))
			if mag: mag.active=true
			spawn_item("metal",Vector2(640,600))
			spawn_item("metal",Vector2(980,600))
			var pad=spawn_item("magnet_pad",Vector2(1100,612))
			if pad: pad.active=true
		"storm":
			spawn_item("robot",Vector2(500,FLOOR_Y-4))
			var f1=spawn_item("fan",Vector2(700,590))
			if f1: f1.active=true; f1.rotation=-0.4
			var f2=spawn_item("updraft",Vector2(920,594))
			if f2: f2.active=true
			spawn_item("paper",Vector2(760,500))
			spawn_item("feather",Vector2(860,450))
		"bounce":
			spawn_item("robot",Vector2(480,FLOOR_Y-4))
			spawn_item("trampoline",Vector2(680,612))
			spawn_item("trampoline",Vector2(900,612))
			spawn_item("rubber",Vector2(760,400))
			spawn_item("gel",Vector2(1040,593))
			spawn_item("bumper",Vector2(1180,594))
		"neon":
			spawn_item("robot",Vector2(520,FLOOR_Y-4))
			var z=spawn_item("zapper",Vector2(760,594))
			if z: z.active=true
			var p=spawn_item("pulsar",Vector2(960,594))
			if p: p.active=true
			spawn_item("speaker",Vector2(1160,590))
			spawn_item("drone",Vector2(880,420))
		"quarry":
			spawn_item("robot",Vector2(420,FLOOR_Y-4))
			for i in range(4): spawn_item("brick",Vector2(700+i*54,608))
			spawn_item("anvil",Vector2(920,400))
			spawn_item("lead",Vector2(1080,603))
			spawn_item("crystal",Vector2(1240,598))
			spawn_item("sandbag",Vector2(560,603))
		"skydock":
			spawn_item("robot_antigrav",Vector2(560,FLOOR_Y-4))
			var hover=spawn_item("hover_pad",Vector2(820,612))
			if hover: hover.active=true
			spawn_item("balloon",Vector2(700,480))
			var deck=spawn_item("plank",Vector2(1040,500))
			var thr=spawn_item("thruster",Vector2(1040,545))
			if deck and thr: make_link(deck,thr)
		"dojo":
			spawn_item("robot",Vector2(480,FLOOR_Y-4))
			var rival=spawn_item("robot_acrobat",Vector2(980,FLOOR_Y-4))
			if rival:
				rival.tint=Color("e06f72")
				for p in rival.parts: p.tint=rival.tint; p.queue_redraw()
			spawn_item("sword",Vector2(560,610))
			spawn_item("spear",Vector2(900,610))
			spawn_item("crate",Vector2(730,594))
		"foundry":
			spawn_item("robot_titan",Vector2(420,FLOOR_Y-4))
			spawn_item("metal",Vector2(720,600))
			spawn_item("lead",Vector2(820,603))
			spawn_item("anvil",Vector2(770,180))
			var chill=spawn_item("chiller",Vector2(1040,603))
			if chill: chill.active=true
			spawn_item("brick",Vector2(1160,608))
		"pinball":
			spawn_item("robot",Vector2(400,FLOOR_Y-4))
			spawn_item("ball",Vector2(520,300))
			spawn_item("bumper",Vector2(720,594))
			spawn_item("bumper",Vector2(900,520))
			spawn_item("bumper",Vector2(1080,594))
			var launch=spawn_item("boost_pad",Vector2(620,612))
			if launch: launch.active=true
			var scatter=spawn_item("scatter_pad",Vector2(1240,612))
			if scatter: scatter.active=true
		"void":
			spawn_item("robot_antigrav",Vector2(500,FLOOR_Y-4))
			var well=spawn_item("grav_well",Vector2(880,420))
			if well: well.active=true
			var vac=spawn_item("vacuum_box",Vector2(880,594))
			if vac: vac.active=true
			spawn_item("cork",Vector2(700,500))
			spawn_item("paper",Vector2(1040,360))
			spawn_item("feather",Vector2(760,280))
		"span":
			spawn_item("robot",Vector2(420,FLOOR_Y-4))
			spawn_item("brick",Vector2(560,608))
			spawn_item("brick",Vector2(1120,608))
			for i in range(5): spawn_item("glass",Vector2(660+i*78,470))
			spawn_item("weight",Vector2(890,200))
			spawn_item("crystal",Vector2(1240,598))
		"clockwork":
			spawn_item("robot",Vector2(460,FLOOR_Y-4))
			var metro=spawn_item("metronome",Vector2(640,593))
			if metro: metro.active=true
			var gyro=spawn_item("gyro",Vector2(800,400))
			if gyro: gyro.angular_velocity=14
			var wheel=spawn_item("wheel",Vector2(980,593))
			if wheel: wheel.active=true
			var mix=spawn_item("rotator",Vector2(1160,594))
			if mix: mix.active=true
		"bath":
			spawn_item("robot",Vector2(500,FLOOR_Y-4))
			spawn_item("soap",Vector2(680,609))
			spawn_item("slime",Vector2(820,607))
			spawn_item("sponge",Vector2(960,603))
			spawn_item("gel",Vector2(1100,593))
			spawn_item("pillow",Vector2(1240,400))
		"reef":
			spawn_item("robot",Vector2(480,FLOOR_Y-4))
			spawn_item("cork",Vector2(640,560))
			spawn_item("cork",Vector2(760,480))
			spawn_item("honeycomb",Vector2(900,600))
			var pump=spawn_item("pump",Vector2(1040,590))
			if pump: pump.active=true
			spawn_item("gel",Vector2(1180,593))
		"junkyard":
			spawn_item("robot",Vector2(440,FLOOR_Y-4))
			spawn_item("tire",Vector2(620,593))
			spawn_item("tire",Vector2(780,400))
			spawn_item("metal",Vector2(920,600))
			spawn_item("crowbar",Vector2(1040,610))
			var roll=spawn_item("wheel",Vector2(1180,593))
			if roll: roll.active=true
		"relay":
			var racer=spawn_item("robot_runner",Vector2(380,FLOOR_Y-4))
			if racer: racer.active=true
			for i in range(3):
				var boost=spawn_item("boost_pad",Vector2(620+i*160,612))
				if boost:
					boost.active=true
					boost.rotation=-0.4
			spawn_item("tire",Vector2(1180,593))
			spawn_item("spring_block",Vector2(1320,610))
	placing=false
	tool="grab"

func clear_scene() -> void:
	release_drag()
	select(null)
	link_first=null
	for link in links:
		if is_instance_valid(link.joint): link.joint.free()
	links.clear()
	for w in welds:
		for j in w.joints:
			if is_instance_valid(j): j.free()
	welds.clear()
	for child in world.get_children():
		if child is LabRobot: child.drop_gun()
	for child in world.get_children():
		if child is LabRobot or child is LabBody or child is Joint2D: child.free()
	fx.particles.clear()
	fx.rings.clear()
	fx.beams.clear()
	fx.arcs.clear()

func spawn_item(kind: String, point: Vector2, count_event: bool=false, rot: float=0.0) -> Node2D:
	var needed=11 if kind in ROBOTS else (LabVehicle.part_count(kind) if kind in VEHICLES else 1)
	if get_tree().get_nodes_in_group("bodies").size()+needed>MAX_BODIES:
		notify(t("Лаборатория заполнена. Удали несколько объектов.","Lab is full. Remove a few objects."))
		return null
	var entity: Node2D
	if kind in ROBOTS:
		var robot=LabRobot.new()
		robot.game=self
		robot.variant=kind
		robot.position=point
		robot.serial=next_id()
		world.add_child(robot)
		entity=robot
	else:
		var body=LabBody.new()
		body.kind=kind
		body.position=point
		body.game=self
		body.serial=next_id()
		match kind:
			"crate": body.dimensions=Vector2(46,46); body.mass=4
			"barrel": body.dimensions=Vector2(36,54); body.mass=6
			"ball": body.dimensions=Vector2(44,44); body.mass=12
			"plank": body.dimensions=Vector2(130,16); body.mass=5
			"metal": body.dimensions=Vector2(50,38); body.mass=16
			"thruster": body.dimensions=Vector2(28,48); body.mass=4
			"mine": body.dimensions=Vector2(48,22); body.mass=3
			"magnet": body.dimensions=Vector2(52,38); body.mass=9; body.health=180
			"fan": body.dimensions=Vector2(48,52); body.mass=10; body.health=150
			"coil": body.dimensions=Vector2(46,58); body.mass=12; body.health=140
			"sticky": body.dimensions=Vector2(28,18); body.mass=1.5; body.health=45
			"glass": body.dimensions=Vector2(70,12); body.mass=2; body.health=22
			"trampoline": body.dimensions=Vector2(86,16); body.mass=25; body.health=260
			"bumper": body.dimensions=Vector2(48,48); body.mass=14; body.health=240
			"weight": body.dimensions=Vector2(50,50); body.mass=48; body.health=400
			"balloon": body.dimensions=Vector2(38,48); body.mass=0.7; body.health=18; body.gravity_factor=-0.42
			"wheel": body.dimensions=Vector2(54,54); body.mass=12; body.health=220
			"c4": body.dimensions=Vector2(32,20); body.mass=2.5; body.health=80
			"laser_cutter": body.dimensions=Vector2(48,26); body.mass=8; body.health=180
			"singularity": body.dimensions=Vector2(36,36); body.mass=16; body.health=260
			"syringe_life","syringe_acid","syringe_nitro","syringe_overclock","syringe_freeze":
				body.dimensions=Vector2(14,38); body.mass=0.8; body.health=60
			"pistol": body.dimensions=Vector2(46,18); body.mass=3; body.health=90
			"revolver": body.dimensions=Vector2(44,20); body.mass=4; body.health=100
			"rifle": body.dimensions=Vector2(78,16); body.mass=5; body.health=120
			"shotgun": body.dimensions=Vector2(70,20); body.mass=6; body.health=110
			"sawed": body.dimensions=Vector2(50,22); body.mass=5.5; body.health=105
			"nailgun": body.dimensions=Vector2(52,22); body.mass=4.5; body.health=95
			"grenade": body.dimensions=Vector2(26,26); body.mass=2.2; body.health=40
			"turret": body.dimensions=Vector2(58,40); body.mass=26; body.health=240
			"drone": body.dimensions=Vector2(50,22); body.mass=1.6; body.health=32; body.gravity_factor=0.22; body.payload=1
			"flak": body.dimensions=Vector2(62,22); body.mass=6.5; body.health=130
			"sword": body.dimensions=Vector2(74,12); body.mass=3.5; body.health=140
			"axe": body.dimensions=Vector2(54,28); body.mass=6; body.health=160
			"spear": body.dimensions=Vector2(96,10); body.mass=3; body.health=110
			"hammer": body.dimensions=Vector2(50,26); body.mass=8; body.health=200
			"knife": body.dimensions=Vector2(36,10); body.mass=1.2; body.health=70
			"katana": body.dimensions=Vector2(78,10); body.mass=3; body.health=120
			"scythe": body.dimensions=Vector2(82,22); body.mass=5; body.health=130
			"mace": body.dimensions=Vector2(48,24); body.mass=7; body.health=180
			"chainsaw": body.dimensions=Vector2(70,20); body.mass=7; body.health=150
			"bat": body.dimensions=Vector2(70,12); body.mass=3; body.health=110
			"whip": body.dimensions=Vector2(104,8); body.mass=1.4; body.health=60
			"plasma_blade": body.dimensions=Vector2(70,12); body.mass=2.8; body.health=100
			"crowbar": body.dimensions=Vector2(62,10); body.mass=4; body.health=160
			"halberd": body.dimensions=Vector2(92,16); body.mass=5.5; body.health=140
			"hook": body.dimensions=Vector2(60,16); body.mass=4; body.health=130
			"railgun": body.dimensions=Vector2(82,14); body.mass=7; body.health=140
			"crossbow": body.dimensions=Vector2(70,22); body.mass=5; body.health=110
			"rocket_gun": body.dimensions=Vector2(64,24); body.mass=8; body.health=120
			"flamer": body.dimensions=Vector2(58,24); body.mass=6; body.health=110
			"freezer": body.dimensions=Vector2(56,18); body.mass=5; body.health=100
			"tesla_gun": body.dimensions=Vector2(54,20); body.mass=5; body.health=105
			"harpoon": body.dimensions=Vector2(78,16); body.mass=6; body.health=125
			"glue_gun": body.dimensions=Vector2(48,20); body.mass=4; body.health=90
			"bouncer": body.dimensions=Vector2(50,18); body.mass=4; body.health=95
			"cannon": body.dimensions=Vector2(72,28); body.mass=14; body.health=200
			"minigun": body.dimensions=Vector2(64,22); body.mass=8; body.health=140
			"pulse_gun": body.dimensions=Vector2(52,22); body.mass=6; body.health=115
			"grapple": body.dimensions=Vector2(50,20); body.mass=4; body.health=100
			"mine_gun": body.dimensions=Vector2(58,24); body.mass=7; body.health=120
			"balloon_gun": body.dimensions=Vector2(46,24); body.mass=3.5; body.health=80
			"vortex": body.dimensions=Vector2(54,26); body.mass=7; body.health=130
			"disc_gun": body.dimensions=Vector2(56,20); body.mass=5; body.health=110
			"taser": body.dimensions=Vector2(42,16); body.mass=2.5; body.health=85
			"cluster": body.dimensions=Vector2(60,22); body.mass=7; body.health=115
			"wind_gun": body.dimensions=Vector2(50,28); body.mass=6; body.health=110
			"extinguisher": body.dimensions=Vector2(26,52); body.mass=5; body.health=90
			"torch": body.dimensions=Vector2(56,12); body.mass=1.5; body.health=60
			"gas_can": body.dimensions=Vector2(34,46); body.mass=5; body.health=45
			"battery": body.dimensions=Vector2(46,30); body.mass=7; body.health=120
			"cable": body.dimensions=Vector2(112,8); body.mass=1.6; body.health=40
			"firework": body.dimensions=Vector2(20,46); body.mass=1.2; body.health=30
			"water_pool": body.dimensions=Vector2(240,120); body.mass=60; body.health=9000
			"oil_pool": body.dimensions=Vector2(200,70); body.mass=40; body.health=9000
			"acid_pool": body.dimensions=Vector2(200,70); body.mass=40; body.health=9000
		if kind in VEHICLES: LabVehicle.setup_chassis(body)
		if kind in PARTS: LabParts.setup(body)
		if kind in VIRUSES:
			body.dimensions=Vector2(28,28); body.mass=0.8; body.health=40
		if TOY_PHYS.has(kind):
			var s=TOY_PHYS[kind]
			body.dimensions=Vector2(float(s.w),float(s.h))
			body.mass=float(s.mass)
			body.health=float(s.get("hp",100))
			if s.has("g"): body.gravity_factor=float(s.g)
		world.add_child(body)
		entity=body
	for b in (entity.parts if entity is LabRobot else [entity]): b.gravity_scale=b.gravity_factor if gravity else 0
	if rot != 0.0:
		if entity is LabBody: entity.rotation = rot
		elif entity is LabRobot:
			for b in entity.parts:
				b.global_position = point + (b.global_position - point).rotated(rot)
				b.rotation += rot
	if entity is LabBody and entity.kind in VEHICLES: LabVehicle.build(self,entity)
	if count_event:
		record("spawn")
		fx.emit_sparks(point,10,LabArt.TEAL)
		play_sound("spawn",0.3)
	return entity

func pick(point: Vector2) -> LabBody:
	var params=PhysicsPointQueryParameters2D.new()
	params.position=point
	params.collision_mask=2
	var hits=get_world_2d().direct_space_state.intersect_point(params,16)
	if not hits.is_empty():
		var hit=hits[-1].collider as LabBody
		if hit and hit.kind not in EPHEMERAL: return hit
	# A small tolerance makes the narrow limbs comfortable to grab on touch screens.
	var closest: LabBody
	var distance=20.0/camera.zoom.x
	for body in get_tree().get_nodes_in_group("bodies"):
		if body.kind in EPHEMERAL or body.kind in FLUIDS: continue
		var d=body.global_position.distance_to(point)
		if d<distance: distance=d; closest=body
	if is_instance_valid(closest): return closest
	# Лужа выбирается последней и по всей своей площади: коллизии у неё нет,
	# поэтому запрос точки её не находит. Так клик по ящику, плавающему в
	# воде, берёт ящик, а клик по пустой воде — саму лужу.
	for body in get_tree().get_nodes_in_group("bodies"):
		if body.kind not in FLUIDS: continue
		var half=body.dimensions*0.5
		if Rect2(body.global_position-half,body.dimensions).has_point(point): return body
	return null

func select(body: LabBody) -> void:
	if is_instance_valid(selected): selected.highlighted=false; selected.queue_redraw()
	selected=body
	if is_instance_valid(selected): selected.highlighted=true; selected.queue_redraw()

func release_drag() -> void:
	if is_instance_valid(dragging) and dragging.kind in VIRUSES:
		var robot=nearest_robot(dragging.global_position,100)
		if robot:
			infect_robot(robot,dragging)
			dragging=null
			mouse_down=false
			panning=false
			return
	if is_instance_valid(dragging) and can_hold(dragging.kind):
		var robot=nearest_robot(dragging.global_position)
		if robot and dragging.global_position.distance_to(robot.parts[6].global_position)<78:
			if equip_gun(robot,dragging):
				dragging=null
	if is_instance_valid(dragging): play_sound("drop",0.2)
	dragging=null
	mouse_down=false
	panning=false

func freeze_selected() -> void:
	if not is_instance_valid(selected): return
	var value=not selected.freeze
	var bodies=selected.ragdoll.parts if is_instance_valid(selected.ragdoll) else LabVehicle.bodies(selected)
	for b in bodies:
		b.freeze=value
		b.linear_velocity=Vector2.ZERO
		b.angular_velocity=0
		b.queue_redraw()
	if is_instance_valid(selected.ragdoll):
		if is_instance_valid(selected.ragdoll.held_gun):
			selected.ragdoll.held_gun.freeze=value
			selected.ragdoll.held_gun.linear_velocity=Vector2.ZERO
			selected.ragdoll.held_gun.angular_velocity=0
			selected.ragdoll.held_gun.queue_redraw()
		if selected.ragdoll.dead:
			selected.ragdoll.corpse_settled=false
			if not value: selected.ragdoll.wake_grace=1.0
	if value: record("freeze")
	play_sound("freeze" if value else "fizz",0.34 if value else 0.2)

func rotate_selected(amount: float) -> void:
	if not is_instance_valid(selected): return
	if is_instance_valid(selected.ragdoll):
		var origin=selected.global_position
		for b in selected.ragdoll.parts:
			b.global_position=origin+(b.global_position-origin).rotated(amount)
			b.rotation+=amount
		if is_instance_valid(selected.ragdoll.held_gun):
			var gun=selected.ragdoll.held_gun
			gun.global_position=origin+(gun.global_position-origin).rotated(amount)
			gun.rotation+=amount
	elif LabVehicle.root(selected):
		var car=LabVehicle.root(selected)
		car.rotation+=amount
		LabVehicle.rebuild(self,car)
	else: selected.rotation+=amount

func activate_selected() -> void:
	if not is_instance_valid(selected): return
	if selected.kind in PARTS:
		LabParts.activate(self,selected)
		return
	var car=LabVehicle.root(selected)
	if car:
		if car.wrecked:
			notify(t("Машина разбита и не заводится","The vehicle is wrecked and will not start"))
			play_sound("switch_off",0.3)
			return
		_gear_changed(car,LabVehicle.cycle_gear(car))
		return
	if is_instance_valid(selected.ragdoll):
		if selected.ragdoll.dead:
			selected.ragdoll.restore()
			notify(t("Робот отремонтирован","Robot repaired"))
			play_sound("revive",0.4)
		elif is_instance_valid(selected.ragdoll.held_gun):
			fire_weapon(selected.ragdoll.held_gun)
		elif try_infect_selected() or try_equip_selected():
			pass
		else:
			selected.ragdoll.toggle_active()
			notify(selected.ragdoll.ability_status())
	elif selected.kind in VIRUSES:
		var host=nearest_robot(selected.global_position,110)
		if host: infect_robot(host,selected)
		else: notify(t("Поднеси чип к роботу","Bring the chip to a robot"))
	elif selected.kind=="turret":
		selected.active=not selected.active
		play_sound("switch_on" if selected.active else "switch_off",0.45)
	elif selected.kind in WEAPONS or selected.kind in EXOTIC or selected.kind in MELEE:
		fire_weapon(selected)
	elif selected.kind=="battery":
		selected.active=not selected.active
		if not selected.active: selected.charge=0.0
		play_sound("switch_on" if selected.active else "switch_off",0.36)
		if selected.active: play_sound("zap",0.3)
		notify(t("Батарея включена","Battery on") if selected.active else t("Батарея выключена","Battery off"))
	elif selected.kind=="firework":
		selected.active=true
		selected.age=0.0
		play_sound("firework",0.4)
		notify(t("Фейерверк зажжён","Firework lit"))
	elif selected.kind=="gas_can":
		selected.ignite(1.0,6.0)
		notify(t("Канистра горит!","The can is alight!"))
	elif selected.kind in FLUIDS:
		notify(t("Лужу можно двигать захватом","Drag the puddle with the grab tool"))
	elif selected.kind in ["barrel","mine","sticky"]:
		selected.active=true
	elif selected.kind=="balloon":
		fx.emit_sparks(selected.global_position,16,LabArt.TEAL)
		play_sound("pop",0.5)
		remove_entity(selected)
	elif selected.kind in ["thruster","magnet","fan","coil","wheel","drone"] or (TOY_PHYS.has(selected.kind) and TOY_PHYS[selected.kind].has("mode")):
		selected.active=not selected.active
		if selected.active:
			if selected.kind in ["thruster","wheel"]: record("launch")
			play_sound("switch_on",0.45)
			if selected.kind=="thruster": play_sound("rocket",0.4)
		else:
			play_sound("switch_off",0.4)
	else: notify(t("У этого предмета нет активации","This object has no activation"))

func _gear_changed(car: LabBody, g: int) -> void:
	notify(LabVehicle.gear_label(self,g,car.kind))
	play_sound("switch_on" if g!=0 else "switch_off",0.4)
	if g!=0: play_sound("rocket",0.35); record("launch")

# Кнопки передач в панели объекта: сразу нужная, без перебора по F.
func set_selected_gear(g: int) -> void:
	var car=LabVehicle.root(selected)
	if car==null: return
	if car.wrecked:
		notify(t("Машина разбита и не заводится","The vehicle is wrecked and will not start"))
		play_sound("switch_off",0.3)
		return
	if LabVehicle.set_gear(car,g): _gear_changed(car,g)

func use_vehicle_ability() -> void:
	var car=LabVehicle.root(selected)
	if car==null:
		notify(t("V — действие машины. Сначала выбери машину","V is the vehicle action. Select a vehicle first"))
		return
	if get_tree().paused or platform.suspended or menu_open: return
	LabVehicle.use_ability(self,car)

func toggle_selected_autonomy() -> void:
	if not is_instance_valid(selected): return
	var robot: LabRobot
	if is_instance_valid(selected.ragdoll): robot=selected.ragdoll
	elif is_instance_valid(selected.holder) and selected.holder is LabRobot: robot=selected.holder
	if not is_instance_valid(robot):
		notify(t("Выбери робота или оружие в его руке","Select a robot or its held weapon"))
		return
	robot.toggle_active()
	notify(robot.ability_status())
	play_sound("switch_on" if robot.active else "switch_off",0.36)

func nearest_robot(point: Vector2, radius: float=96.0) -> LabRobot:
	var best: LabRobot
	var dist=radius
	for robot in get_tree().get_nodes_in_group("robots"):
		if robot.dead or not is_instance_valid(robot) or robot.parts.size()<7: continue
		var d=minf(robot.parts[6].global_position.distance_to(point),robot.parts[1].global_position.distance_to(point))
		if d<dist: dist=d; best=robot
	return best

func nearest_weapon(point: Vector2, radius: float=96.0) -> LabBody:
	var best: LabBody
	var dist=radius
	for body in get_tree().get_nodes_in_group("bodies"):
		if not can_hold(body.kind) or is_instance_valid(body.holder): continue
		var d=body.global_position.distance_to(point)
		if d<dist: dist=d; best=body
	return best

func weapon_grip_local(gun: LabBody) -> Vector2:
	var w=gun.dimensions.x
	var h=gun.dimensions.y
	match gun.kind:
		"grenade":
			return Vector2.ZERO
		"scythe":
			return Vector2(-w*0.06,h*0.28)
		"axe","hammer","mace","hook":
			return Vector2(-w*0.36,h*0.04)
		_:
			if gun.kind in MELEE:
				return Vector2(-w*0.40,h*0.02)
			return Vector2(-w*0.22,h*0.22)

func weapon_aim_angle(gun: LabBody, face: float) -> float:
	if gun.kind in ["grenade","scythe"]: return 0.0
	return Vector2(face,0.18).angle()

func robot_should_aim(robot: LabRobot) -> bool:
	if not is_instance_valid(robot) or robot.dead or not is_instance_valid(robot.held_gun): return false
	if robot.held_gun.kind in MELEE or robot.held_gun.kind=="grenade": return false
	if placing or tool!="grab" or menu_open or help_open: return false
	return is_instance_valid(selected) and (selected==robot.held_gun or selected.ragdoll==robot)

func aimed_weapon() -> LabBody:
	if not is_instance_valid(selected): return null
	if is_instance_valid(selected.holder) and selected.holder is LabRobot and robot_should_aim(selected.holder):
		return selected
	if is_instance_valid(selected.ragdoll) and robot_should_aim(selected.ragdoll):
		return selected.ragdoll.held_gun
	return null

func equip_gun(robot: LabRobot, gun: LabBody, announce: bool=true) -> bool:
	if not is_instance_valid(robot) or robot.dead or not is_instance_valid(gun) or not can_hold(gun.kind): return false
	if not robot.is_part_attached(6):
		# Правая рука оторвана — попробуем левую
		if gun.kind in MELEE and robot.is_part_attached(4):
			return equip_gun_left(robot, gun, announce)
		if announce: notify(t("У робота оторвана рука!","Robot cannot hold weapon: arm severed!"))
		return false
	if is_instance_valid(gun.holder) and gun.holder!=robot:
		if gun.holder is LabRobot and gun.holder.held_gun_left==gun:
			gun.holder.drop_gun_left()
		else:
			gun.holder.drop_gun()
	if is_instance_valid(robot.held_gun) and robot.held_gun!=gun:
		# Правая рука занята — для melee даём в левую
		if gun.kind in MELEE and robot.is_part_attached(4):
			return equip_gun_left(robot, gun, announce)
		robot.drop_gun()
	var face=robot.hold_face()
	var hand=robot.parts[6]
	var palm=robot.palm()
	var grip=weapon_grip_local(gun)
	var aim=weapon_aim_angle(gun,face)
	gun.sleeping=false
	gun.freeze=false
	gun.rotation=aim
	gun.global_position=palm-grip.rotated(aim)
	gun.linear_velocity=hand.linear_velocity
	gun.angular_velocity=0
	gun.grip_local=grip
	gun.set_deferred("lock_rotation", true)
	gun.gravity_scale=0.0
	var joint=PinJoint2D.new()
	world.add_child(joint)
	joint.global_position=palm
	joint.node_a=joint.get_path_to(hand)
	joint.node_b=joint.get_path_to(gun)
	joint.disable_collision=true
	joint.softness=0.0
	joint.angular_limit_enabled=false
	robot.gun_joint=joint
	robot.held_gun=gun
	gun.holder=robot
	gun.angular_damp=12.0
	for part in robot.parts:
		gun.add_collision_exception_with(part)
		part.add_collision_exception_with(gun)
	# Также исключаем коллизию с оружием в другой руке
	if is_instance_valid(robot.held_gun_left):
		gun.add_collision_exception_with(robot.held_gun_left)
		robot.held_gun_left.add_collision_exception_with(gun)
	if announce:
		if gun.kind=="grenade":
			notify(t("Граната в руках. F — бросок.","Grenade in hand. Press F to throw."))
		elif gun.kind=="chainsaw":
			notify(t("Пила в руках. F — запуск.","Chainsaw in hand. Press F to rev."))
		elif gun.kind in MELEE:
			notify(t("Клинок в руках. F — удар.","Blade in hand. Press F to strike."))
		else:
			notify(t("Оружие в руках. F — выстрел.","Weapon in hand. Press F to fire."))
		play_sound("equip",0.42)
	return true

func equip_gun_left(robot: LabRobot, gun: LabBody, announce: bool=true) -> bool:
	if not is_instance_valid(robot) or robot.dead or not is_instance_valid(gun): return false
	# Левая рука — только melee
	if gun.kind not in MELEE: return false
	if not robot.is_part_attached(4):
		if announce: notify(t("Левая рука оторвана!","Left arm severed!"))
		return false
	if is_instance_valid(gun.holder) and gun.holder!=robot:
		if gun.holder is LabRobot and gun.holder.held_gun_left==gun:
			gun.holder.drop_gun_left()
		elif gun.holder is LabRobot:
			gun.holder.drop_gun()
	if is_instance_valid(robot.held_gun_left) and robot.held_gun_left!=gun:
		robot.drop_gun_left()
	var face=robot.hold_face()
	var hand=robot.parts[4]
	var palm_pos=robot.palm_left()
	var grip=weapon_grip_local(gun)
	# Зеркалим grip по X для левой руки
	grip.x = -grip.x
	var aim=weapon_aim_angle(gun,-face)
	gun.sleeping=false
	gun.freeze=false
	gun.rotation=aim
	gun.global_position=palm_pos-grip.rotated(aim)
	gun.linear_velocity=hand.linear_velocity
	gun.angular_velocity=0
	gun.grip_local=grip
	gun.set_deferred("lock_rotation", true)
	gun.gravity_scale=0.0
	var joint=PinJoint2D.new()
	world.add_child(joint)
	joint.global_position=palm_pos
	joint.node_a=joint.get_path_to(hand)
	joint.node_b=joint.get_path_to(gun)
	joint.disable_collision=true
	joint.softness=0.0
	joint.angular_limit_enabled=false
	robot.gun_joint_left=joint
	robot.held_gun_left=gun
	gun.holder=robot
	gun.angular_damp=12.0
	for part in robot.parts:
		gun.add_collision_exception_with(part)
		part.add_collision_exception_with(gun)
	# Исключаем коллизию с оружием в другой руке
	if is_instance_valid(robot.held_gun):
		gun.add_collision_exception_with(robot.held_gun)
		robot.held_gun.add_collision_exception_with(gun)
	if announce:
		notify(t("Клинок в левой руке. F — удар.","Blade in left hand. Press F to strike."))
		play_sound("equip",0.42)
	return true

func nearest_virus(point: Vector2, radius: float=96.0) -> LabBody:
	var best: LabBody
	var dist=radius
	for body in get_tree().get_nodes_in_group("bodies"):
		if body.kind not in VIRUSES: continue
		var d=body.global_position.distance_to(point)
		if d<dist: dist=d; best=body
	return best

func infect_robot(robot: LabRobot, chip: LabBody, announce: bool=true) -> bool:
	if not is_instance_valid(robot) or robot.dead or not is_instance_valid(chip) or chip.kind not in VIRUSES: return false
	robot.infect(chip.kind)
	if announce:
		notify(t("Поведение: ","Behavior: ")+virus_label(chip.kind))
		play_sound("chip",0.4)
		fx.emit_sparks(robot.parts[1].global_position,14,robot.virus_color())
	remove_entity(chip)
	return true

func try_infect_selected() -> bool:
	if not is_instance_valid(selected): return false
	if selected.kind in VIRUSES:
		var robot=nearest_robot(selected.global_position,110)
		if robot: return infect_robot(robot,selected)
	elif is_instance_valid(selected.ragdoll) and not selected.ragdoll.dead:
		var chip=nearest_virus(selected.global_position,100)
		if chip: return infect_robot(selected.ragdoll,chip)
	return false

func virus_label(kind: String) -> String:
	match kind:
		"virus_rage": return t("Ярость","Rage")
		"virus_dance": return t("Танец","Dance")
		"virus_panic": return t("Паника","Panic")
		"virus_guard": return t("Страж","Guard")
		"virus_leap": return t("Прыжок","Leap")
		"virus_orbit": return t("Орбита","Orbit")
		"virus_float": return t("Левитация","Levitation")
		"virus_hunter": return t("Охотник","Hunter")
		"virus_follow": return t("Стая","Flock")
		"virus_spin": return t("Вихрь","Spin")
	return kind

func try_equip_selected() -> bool:
	if not is_instance_valid(selected): return false
	if can_hold(selected.kind):
		var robot=nearest_robot(selected.global_position)
		if robot: return equip_gun(robot,selected)
	elif is_instance_valid(selected.ragdoll) and not selected.ragdoll.dead:
		var gun=nearest_weapon(selected.global_position)
		if gun: return equip_gun(selected.ragdoll,gun)
	return false

func drop_selected_gun() -> void:
	if not is_instance_valid(selected): return
	if can_hold(selected.kind) and is_instance_valid(selected.holder):
		if selected.holder is LabRobot and selected.holder.held_gun_left == selected:
			selected.holder.drop_gun_left()
		else:
			selected.holder.drop_gun()
		notify(t("Оружие выброшено","Weapon dropped"))
	elif is_instance_valid(selected.ragdoll):
		if is_instance_valid(selected.ragdoll.held_gun):
			selected.ragdoll.drop_gun()
			notify(t("Оружие выброшено","Weapon dropped"))
		elif is_instance_valid(selected.ragdoll.held_gun_left):
			selected.ragdoll.drop_gun_left()
			notify(t("Оружие выброшено","Weapon dropped"))

func fire_weapon(gun: LabBody) -> void:
	if not is_instance_valid(gun) or gun.freeze: return
	if get_tree().paused or platform.suspended or menu_open: return
	if gun.kind in MELEE:
		swing_melee(gun)
		return
	if gun.kind=="turret": return
	if gun.kind=="grenade":
		_throw_grenade(gun)
		return
	if gun.mechanism_cooldown>0: return
	if GUN_SPECIAL.has(gun.kind):
		_fire_special(gun)
		return
	if not GUN_FIRE.has(gun.kind): return
	var spec=GUN_FIRE[gun.kind]
	var dir=Vector2.RIGHT.rotated(gun.rotation)
	var muzzle=gun.global_position+dir*(gun.dimensions.x*0.52)
	gun.mechanism_cooldown=float(spec.wait)
	for i in range(int(spec.n)):
		var shot=dir.rotated(randf_range(-float(spec.spread),float(spec.spread)))
		_spawn_projectile(str(spec.shot),muzzle,shot*float(spec.speed),float(spec.force),gun)
	gun.apply_central_impulse(-dir*float(spec.kick))
	if is_instance_valid(gun.holder) and gun.holder is LabRobot:
		gun.holder.play_recoil(dir,float(spec.kick))
	fx.emit_sparks(muzzle,8,LabArt.AMBER,dir*220)
	fx.beam(muzzle,muzzle+dir*36)
	fx.flash(muzzle,24.0,Color(1.0,0.92,0.7))
	var heavy=gun.kind in ["shotgun","sawed","cannon","railgun"]
	camera_shake=maxf(camera_shake,3.5 if heavy else 1.4)
	if heavy: impact_flash=minf(1.0,impact_flash+0.18)
	var snd=gun_sound(gun.kind)
	play_sound(snd[0],snd[1])
	if heavy: play_sound("shot",0.3)

func swing_melee(gun: LabBody) -> void:
	if gun.kind=="chainsaw":
		gun.active=not gun.active
		play_sound("switch_on" if gun.active else "switch_off",0.4)
		if gun.active: play_sound("rocket",0.22)
		notify(t("Пила включена","Chainsaw on") if gun.active else t("Пила выключена","Chainsaw off"))
		gun.queue_redraw()
		return
	if gun.mechanism_cooldown>0: return
	var spec=MELEE_STATS.get(gun.kind,{"wait":0.32,"spin":150.0,"shove":160.0,"hit":28.0})
	var dir=Vector2.RIGHT.rotated(gun.rotation)
	if is_instance_valid(gun.holder) and gun.holder is LabRobot:
		var aim_pt=gun.holder.current_aim_point()
		if aim_pt!=Vector2.INF:
			var d_vec=aim_pt-gun.global_position
			if d_vec.length()>15.0:
				dir=d_vec.normalized()
		else:
			# Без явного прицела замах шёл туда, куда случайно смотрел клинок:
			# после предыдущего удара он мог висеть под любым углом, и робот
			# с равной охотой рубил воздух за спиной. Теперь удар всегда идёт
			# туда, куда робот повёрнут, с небольшим подъёмом вверх.
			dir=Vector2(gun.holder.hold_face(),-0.12).normalized()
	gun.mechanism_cooldown=float(spec.wait)
	gun.payload=float(spec.hit)
	gun.impact_cooldown=0
	var is_thrust=bool(spec.get("thrust",0))
	var is_slam=gun.kind in ["hammer","mace","bat"]
	if is_instance_valid(gun.holder) and gun.holder is LabRobot:
		if is_thrust:
			gun.holder.play_thrust(dir,float(spec.shove)/250.0,spec)
		elif is_slam:
			gun.holder.play_slam(dir,float(spec.spin)/160.0,spec)
		else:
			gun.holder.play_slash(dir,float(spec.spin)/160.0,spec)
	else:
		if is_thrust:
			gun.apply_central_impulse(dir*float(spec.shove))
		else:
			var side=1.0 if dir.x>=0 else -1.0
			gun.apply_torque_impulse(float(spec.spin)*side)
			gun.apply_central_impulse(dir*(float(spec.shove)*0.45)+dir.orthogonal()*side*50)
		var tip=gun.global_position+dir*(gun.dimensions.x*0.45)
		fx.emit_sparks(tip,8 if gun.kind=="plasma_blade" else 6,LabArt.TEAL if gun.kind=="plasma_blade" else LabArt.AMBER,dir*120)
		play_sound("hit",0.4)
		camera_shake=maxf(camera_shake,1.6)

func nearest_strike(origin: Vector2, dir: Vector2, radius: float, gun: LabBody) -> LabBody:
	# Луч бьёт только то, что перед стволом. Раньше цель выбиралась как
	# ближайшее тело в радиусе в любую сторону, и тесла в руке робота
	# стреляла в ящик за спиной, в лужу под ногами или во второе оружие.
	var best: LabBody
	var best_score=INF
	var holder=gun.holder if is_instance_valid(gun.holder) else null
	for body in get_tree().get_nodes_in_group("bodies"):
		if body==gun or body.kind in EPHEMERAL or body.kind in FLUIDS or body.is_queued_for_deletion(): continue
		if holder and (body.ragdoll==holder or body==holder or body.holder==holder): continue
		var offset=body.global_position-origin
		var along=offset.dot(dir)
		if along<=0.0 or along>radius: continue
		var lateral=absf(offset.cross(dir))
		# Узкий конус с запасом на размер тела: крупную цель не пропустит,
		# а стоящее сбоку не зацепит.
		if lateral>24.0+maxf(body.dimensions.x,body.dimensions.y)*0.5+along*0.18: continue
		var score=along+lateral*2.0
		if score<best_score: best_score=score; best=body
	return best

func _fire_special(gun: LabBody) -> void:
	var spec=GUN_SPECIAL[gun.kind]
	var dir=Vector2.RIGHT.rotated(gun.rotation)
	var muzzle=gun.global_position+dir*(gun.dimensions.x*0.52)
	gun.mechanism_cooldown=float(spec.wait)
	match str(spec.mode):
		"flame":
			for i in range(4):
				var shot=dir.rotated(randf_range(-0.22,0.22))
				_spawn_projectile("flame",muzzle,shot*randf_range(420,640),8,gun)
			fx.emit_sparks(muzzle,10,LabArt.AMBER,dir*200)
			play_sound("flame",0.34)
		"foam":
			for i in range(5):
				var shot=dir.rotated(randf_range(-0.26,0.26))
				_spawn_projectile("foam",muzzle,shot*randf_range(360,520),0,gun)
			fx.emit_sparks(muzzle,8,Color("dfeef5"),dir*150)
			play_sound("spray",0.3)
		"beam":
			var target=nearest_strike(muzzle,dir,float(spec.range),gun)
			if target:
				var hurt=float(spec.hurt)
				if gun.kind=="taser" and is_instance_valid(target.ragdoll): hurt*=2.4
				target.damage(hurt,(target.global_position-muzzle).normalized()*target.mass*140)
				fx.beam(muzzle,target.global_position)
				play_sound("zap",0.4)
			else:
				fx.beam(muzzle,muzzle+dir*float(spec.range)*0.4)
				play_sound("zap",0.2)
		"wave":
			for body in get_tree().get_nodes_in_group("bodies"):
				if body==gun or body.kind in EPHEMERAL: continue
				var offset=body.global_position-muzzle
				if offset.length()<220 and dir.dot(offset.normalized())>0.55:
					body.damage(14,offset.normalized()*body.mass*220)
			fx.beam(muzzle,muzzle+dir*90)
			fx.emit_sparks(muzzle,12,LabArt.TEAL,dir*240)
			play_sound("pulse",0.4)
			camera_shake=maxf(camera_shake,2.2)
		"vortex":
			for body in get_tree().get_nodes_in_group("bodies"):
				if body==gun or body.kind in EPHEMERAL: continue
				var offset=muzzle-body.global_position
				var d=offset.length()
				if d>20 and d<280:
					body.apply_central_impulse(offset.normalized()*(1-d/280.0)*body.mass*90)
			fx.emit_sparks(muzzle,14,LabArt.TEAL)
			play_sound("rocket",0.3)
		"wind":
			for body in get_tree().get_nodes_in_group("bodies"):
				if body==gun or body.kind in EPHEMERAL: continue
				var offset=body.global_position-muzzle
				if offset.length()<320 and dir.dot(offset.normalized())>0.62:
					body.apply_central_force(dir*(1-offset.length()/320.0)*body.mass*2400)
			fx.emit_sparks(muzzle+dir*24,6,Color("9fe8ff"),dir*220)
			play_sound("spray",0.24)
		"grapple":
			_spawn_projectile("tether",muzzle,dir*980,18,gun)
			play_sound("thunk",0.34)
			play_sound("link",0.2)
		"cluster":
			for i in range(3):
				var nade=spawn_item("grenade",muzzle+dir*12)
				if nade==null: break
				nade.linear_velocity=dir.rotated(randf_range(-0.28,0.28))*randf_range(380,560)+Vector2(0,-80)
				nade.active=true
				nade.mechanism_cooldown=0.75
			play_sound("shot_heavy",0.42)
		"lob":
			var lobbed=spawn_item(str(spec.spawn),muzzle+dir*10)
			if lobbed:
				lobbed.linear_velocity=dir*float(spec.speed)+Vector2(0,-120)
				lobbed.angular_velocity=randf_range(-6,6)
			play_sound("thunk",0.34)
	gun.apply_central_impulse(-dir*40)
	if is_instance_valid(gun.holder) and gun.holder is LabRobot:
		gun.holder.play_recoil(dir,90.0)

func _throw_grenade(gun: LabBody) -> void:
	var dir=Vector2.RIGHT.rotated(gun.rotation)
	var held=is_instance_valid(gun.holder)
	if held and gun.holder is LabRobot:
		gun.holder.play_thrust(dir,1.15)
		gun.holder.drop_gun()
	elif held:
		gun.holder.drop_gun()
	gun.active=true
	gun.mechanism_cooldown=1.2
	gun.impact_cooldown=0.28
	gun.sleeping=false
	gun.freeze=false
	if held:
		gun.apply_central_impulse(dir*440+Vector2(0,-200))
		gun.apply_torque_impulse(randf_range(-12,12))
	fx.emit_sparks(gun.global_position,8,LabArt.RED,dir*80)
	play_sound("spawn",0.4)
	notify(t("Фитиль зажжён","Fuse is lit"))

func _spawn_slug(origin: Vector2, velocity: Vector2, force: float, gun: LabBody) -> void:
	_spawn_projectile("slug",origin,velocity,force,gun)

func _spawn_projectile(kind: String, origin: Vector2, velocity: Vector2, force: float, gun: LabBody) -> void:
	var bodies=get_tree().get_nodes_in_group("bodies")
	var cap=40 if kind=="nail" else 28
	var extras: Array=[]
	for body in bodies:
		if body.kind==kind: extras.append(body)
	if extras.size()>=cap or bodies.size()>=MAX_BODIES:
		var victim=extras[0] if not extras.is_empty() else null
		if extras.size()>=2:
			for body in extras:
				if body.age>victim.age: victim=body
		if victim: remove_entity(victim)
		if get_tree().get_nodes_in_group("bodies").size()>=MAX_BODIES: return
	var shot=LabBody.new()
	shot.kind=kind
	if kind=="nail" or kind=="tether":
		shot.dimensions=Vector2(18,4); shot.mass=0.22; shot.gravity_factor=0.5
	elif kind=="emp":
		shot.dimensions=Vector2(16,16); shot.mass=0.4; shot.gravity_factor=0.08
	elif kind=="rocket":
		shot.dimensions=Vector2(20,8); shot.mass=1.2; shot.gravity_factor=0.35
	elif kind=="chill":
		shot.dimensions=Vector2(14,14); shot.mass=0.4; shot.gravity_factor=0.12
	elif kind=="bounce":
		shot.dimensions=Vector2(12,12); shot.mass=0.5; shot.gravity_factor=0.25; shot.health=5
	elif kind=="disc":
		shot.dimensions=Vector2(22,22); shot.mass=1.4; shot.gravity_factor=0.2; shot.health=4
	elif kind=="flame":
		shot.dimensions=Vector2(12,12); shot.mass=0.15; shot.gravity_factor=0.4
	elif kind=="cannonball":
		shot.dimensions=Vector2(22,22); shot.mass=8; shot.gravity_factor=0.85
	else:
		shot.dimensions=Vector2(10,10); shot.mass=0.35; shot.gravity_factor=0.18
	if kind not in ["bounce","disc"]: shot.health=1
	shot.payload=force
	shot.position=origin
	shot.rotation=velocity.angle()
	shot.game=self
	shot.source=gun
	shot.serial=next_id()
	world.add_child(shot)
	if kind=="disc": shot.angular_velocity=18
	shot.gravity_scale=shot.gravity_factor if gravity else 0
	shot.linear_velocity=velocity
	shot.linear_damp=0.05
	shot.angular_damp=0.2
	if is_instance_valid(gun):
		shot.add_collision_exception_with(gun)
		if is_instance_valid(gun.holder):
			for part in gun.holder.parts:
				shot.add_collision_exception_with(part)

func flammability(kind: String) -> float:
	return float(FLAMMABLE.get(kind,0.0))

func conductivity(kind: String) -> float:
	return float(CONDUCTIVE.get(kind,0.0))

func ignite_area(point: Vector2, radius: float, seconds: float=5.0) -> void:
	# Поджигает всё горючее в радиусе. Роботы считаются один раз: пламя на
	# каждой из одиннадцати пластин — это всё тот же один горящий робот.
	var seen: Dictionary={}
	for body in get_tree().get_nodes_in_group("bodies"):
		if not is_instance_valid(body) or body.is_queued_for_deletion(): continue
		var d=body.global_position.distance_to(point)
		if d>radius: continue
		if body.is_attached_robot_part():
			if seen.has(body.ragdoll): continue
			seen[body.ragdoll]=true
		body.ignite(1.0-d/radius*0.55,seconds)

func electrify_area(point: Vector2, radius: float, power: float=1.0) -> void:
	for body in get_tree().get_nodes_in_group("bodies"):
		if not is_instance_valid(body) or body.is_queued_for_deletion(): continue
		var d=body.global_position.distance_to(point)
		if d<=radius: body.electrify(power*(1.0-d/radius*0.6))

func pulse(point: Vector2) -> void:
	if get_tree().paused: return
	fire_timer=0.16
	var target=pick(point)
	var start=point+Vector2(-340,-90)
	fx.beam(start,point)
	if target: target.damage(25,Vector2(340,-105)*sqrt(target.mass))
	camera_shake=maxf(camera_shake,2)
	play_sound("pulse",0.3)
	record("pulse")

func explode(point: Vector2, radius: float=220, power: float=1) -> void:
	if platform.suspended or menu_open: return
	fx.explosion(point,radius)
	camera_shake=maxf(camera_shake,14*power)
	impact_flash=minf(1.0,impact_flash+0.65*power)
	play_sound("explosion",0.65)
	# Робот — это 11 тел в группе "bodies", и раньше каждое получало полный
	# урон и полное отбрасывание: взрыв бил по роботу одиннадцать раз подряд
	# и убивал его даже у самой кромки радиуса. Теперь на робота приходится
	# ровно одно попадание — по той части, что ближе всего к центру.
	var doll_hit: Dictionary={}
	var singles: Array=[]
	for body in get_tree().get_nodes_in_group("bodies"):
		if body.is_queued_for_deletion(): continue
		var distance=body.global_position.distance_to(point)
		if distance>=radius: continue
		if body.is_attached_robot_part():
			var prev=doll_hit.get(body.ragdoll)
			if prev==null or distance<float(prev[1]): doll_hit[body.ragdoll]=[body,distance]
		else:
			singles.append([body,distance])
	for entry in singles: _blast_body(entry[0],point,float(entry[1]),radius,power)
	for key in doll_hit: _blast_body(doll_hit[key][0],point,float(doll_hit[key][1]),radius,power)
	record("explosion")

func _blast_body(body: LabBody, point: Vector2, distance: float, radius: float, power: float) -> void:
	if not is_instance_valid(body) or body.is_queued_for_deletion(): return
	var strength=pow(1-distance/radius,0.7)
	var dir=((body.global_position-point)+Vector2(0,-35)).normalized()
	# Масса для импульса — вся масса робота, а не одной пластины: раньше
	# суммарный разгон набирался из одиннадцати вызовов, теперь он один.
	var push_mass=body.mass
	if body.is_attached_robot_part():
		push_mass=0.0
		for p in body.ragdoll.connected_parts():
			if is_instance_valid(p): push_mass+=p.mass
		if push_mass<=0.0: push_mass=body.mass
	body.damage(160*strength*power,dir*1500*strength*sqrt(push_mass)*power)

func shatter(body: LabBody) -> void:
	if not is_instance_valid(body) or body.is_queued_for_deletion(): return
	var is_glass=body.kind in ["glass","crystal"]
	var debris_color=Color("8edce8") if is_glass else Color("bc8a52")
	fx.emit_sparks(body.global_position,24,LabArt.TEAL if is_glass else LabArt.AMBER)
	var blast_vel = body.linear_velocity if body.linear_velocity.length() > 40.0 else Vector2.ZERO
	for i in range(6 if is_glass else 4):
		if get_tree().get_nodes_in_group("bodies").size()>=MAX_BODIES: break
		var piece=LabBody.new()
		piece.kind="debris"
		piece.dimensions=Vector2(12,8)
		piece.tint=debris_color
		piece.mass=0.5
		piece.position=body.global_position+Vector2(randf_range(-15,15),randf_range(-15,15))
		piece.game=self
		piece.serial=next_id()
		world.add_child(piece)
		piece.linear_velocity=blast_vel * 0.75 + Vector2(randf_range(-180,180),randf_range(-240,-70))
		piece.angular_velocity=randf_range(-10,10)
	play_sound("glass" if is_glass else "wood",0.5 if is_glass else 0.45)
	remove_entity(body)
	if not is_glass: record("crate")

func remove_entity(body: LabBody) -> void:
	if not is_instance_valid(body) or body.is_queued_for_deletion(): return
	if is_instance_valid(body.holder): body.holder.drop_gun()
	var car=LabVehicle.root(body)
	var entity=body.ragdoll if is_instance_valid(body.ragdoll) else (car if car else body)
	if entity is LabRobot: entity.drop_gun()
	var removing=entity.parts if entity is LabRobot else LabVehicle.bodies(entity)
	if car:
		# Машина удаляется целиком: кузов, колёса и шарниры подвески.
		LabVehicle.free_joints(car)
		for w in car.wheels:
			if is_instance_valid(w): w.queue_free()
	var wake_center=body.global_position
	var wake_radius=maxf(body.dimensions.x,body.dimensions.y)+155.0
	# Godot does not always wake a sleeping body when the RigidBody2D beneath
	# it is deleted. Wake nearby bodies explicitly so gravity can take over.
	for nearby in get_tree().get_nodes_in_group("bodies"):
		if nearby not in removing and nearby.global_position.distance_to(wake_center)<wake_radius:
			nearby.sleeping=false
			nearby.apply_central_impulse(Vector2(0,0.15)*nearby.mass)
			if is_instance_valid(nearby.ragdoll) and nearby.ragdoll.dead:
				nearby.ragdoll.wake_for(1.2)
	if selected in removing: select(null)
	if dragging in removing:
		dragging=null
		mouse_down=false
		panning=false
	if link_first in removing: link_first=null
	for b in removing:
		if b is LabBody: LabParts.unweld_all(self,b)
	for i in range(links.size()-1,-1,-1):
		if links[i].a in removing or links[i].b in removing:
			if is_instance_valid(links[i].joint): links[i].joint.queue_free()
			links.remove_at(i)
	entity.queue_free()

func make_link(a: LabBody, b: LabBody, count_event: bool=false) -> void:
	if a==b or links.size()>=60: return
	for link in links:
		if (link.a==a and link.b==b) or (link.a==b and link.b==a): return
	var joint=DampedSpringJoint2D.new()
	joint.position=a.global_position
	joint.rotation=(b.global_position-a.global_position).angle()-PI/2
	joint.length=maxf(a.global_position.distance_to(b.global_position),5)
	joint.rest_length=joint.length
	joint.stiffness=45
	joint.damping=5
	# Буксир и трос вертолёта: пружина 45 растягивалась под грузом на сотни
	# пикселей. Жёсткость по массе лёгкого конца — висящий груз провисает на ~15,
	# демпфер гасит ту же долю скорости за шаг, что и подвеска машин.
	if LabVehicle.root(a) or LabVehicle.root(b):
		joint.stiffness=clampf(minf(a.mass,b.mass)*60.0,45.0,20000.0)
		var k_inv=1.0/maxf(a.mass,0.05)+1.0/maxf(b.mass,0.05)
		joint.damping=-log(1.0-0.08)/((1.0/float(Engine.physics_ticks_per_second))*k_inv)
	world.add_child(joint)
	joint.node_a=joint.get_path_to(a)
	joint.node_b=joint.get_path_to(b)
	links.append({"a":a,"b":b,"joint":joint})
	if count_event: record("link"); play_sound("link",0.36)

func zoom_at(factor: float) -> void:
	var old=camera.zoom.x
	var next=clampf(old*factor,0.4,1.8)
	var mouse=get_viewport().get_mouse_position()-get_viewport_rect().size/2
	camera_center+=mouse/old-mouse/next
	camera.zoom=Vector2.ONE*next

func reset_view() -> void:
	camera_center=Vector2(750,450) if mobile else Vector2(640,400)
	camera.zoom=Vector2.ONE*(0.72 if mobile else 1.0)

func record(key: String) -> void:
	stats[key]=int(stats.get(key,0))+1
	for i in range(GOALS.size()):
		if i not in completed and int(stats.get(GOALS[i][0],0))>=GOALS[i][1]:
			completed.append(i)
			notify(t("Открытие: ","Discovery: ")+t(GOALS[i][2],GOALS[i][3]))
	save_progress()

func notify(message: String) -> void:
	toast=message
	toast_time=3.5

func save_progress() -> bool:
	if test_mode: return true
	return platform.save_data({"version":1,"stats":stats,"completed":completed,"muted":muted,"lang":lang_override,"scene":cached_scene})

func body_data(body: LabBody) -> Dictionary:
	return {"id":body.serial,"kind":body.kind,"x":body.global_position.x,"y":body.global_position.y,"r":body.rotation,"vx":body.linear_velocity.x,"vy":body.linear_velocity.y,"av":body.angular_velocity,"hp":body.health,"frozen":body.freeze,"active":body.active,"burn":body.burning,"wet":body.wet,"chg":body.charge,"soot":body.scorch}

func save_snapshot(show_message: bool=false) -> void:
	var entities: Array=[]
	for child in world.get_children():
		if child.is_queued_for_deletion(): continue
		if child is LabRobot:
			var parts: Array=[]
			for b in child.parts: parts.append(body_data(b))
			var held=child.held_gun.serial if is_instance_valid(child.held_gun) else 0
			var severed: Array=[]
			for j_idx in range(child.joints.size()):
				if not is_instance_valid(child.joints[j_idx]): severed.append(j_idx)
			entities.append({"kind":child.variant,"x":child.position.x,"y":child.position.y,"hp":child.health,"active":child.active,"tint":child.tint.to_html(),"parts":parts,"held":held,"virus":child.virus,"severed":severed})
		elif child is LabBody and child.kind not in EPHEMERAL and child.kind!=LabVehicle.WHEEL:
			var entry=body_data(child)
			# Колёса не сохраняются отдельно: машина при загрузке собирает их заново.
			if child.kind in VEHICLES or child.kind=="c_motor": entry["gear"]=child.gear
			entities.append(entry)
	var wires: Array=[]
	for link in links:
		if is_instance_valid(link.a) and is_instance_valid(link.b): wires.append([link.a.serial,link.b.serial])
	var bonds: Array=[]
	for w in welds:
		if is_instance_valid(w.a) and is_instance_valid(w.b): bonds.append([w.a.serial,w.b.serial,w.type])
	cached_scene={"entities":entities,"links":wires,"welds":bonds,"name":scene_name,"gravity":gravity}
	var ok=save_progress()
	if show_message: notify(t("Сцена сохранена","Scene saved") if ok else t("Не удалось сохранить. Проверь хранилище браузера.","Could not save. Check browser storage."))

func apply_body_data(body: LabBody, data: Dictionary) -> void:
	body.serial=int(data.get("id",next_id()))
	counter=maxi(counter,body.serial)
	body.global_position=Vector2(float(data.get("x",0)),float(data.get("y",0)))
	body.rotation=float(data.get("r",0))
	body.linear_velocity=Vector2(float(data.get("vx",0)),float(data.get("vy",0)))
	body.angular_velocity=float(data.get("av",0))
	body.health=clampf(float(data.get("hp",body.max_health)),0,body.max_health)
	body.freeze=bool(data.get("frozen",false))
	body.active=bool(data.get("active",false))
	body.burning=maxf(0.0,float(data.get("burn",0.0)))
	body.wet=clampf(float(data.get("wet",0.0)),0.0,1.0)
	body.charge=clampf(float(data.get("chg",0.0)),0.0,1.0)
	body.scorch=clampf(float(data.get("soot",0.0)),0.0,1.0)
	body.queue_redraw()

func restore_snapshot(data: Dictionary) -> void:
	if not data.get("entities",[]) is Array: return
	clear_scene()
	gravity=bool(data.get("gravity",true))
	scene_name=str(data.get("name","sandbox"))
	if is_instance_valid(arena): arena.set_theme(scene_theme(scene_name))
	var mapping: Dictionary={}
	var held_pairs: Array=[]
	for entry in data.get("entities",[]):
		if not entry is Dictionary or entry.get("kind","") not in ITEMS: continue
		var entity=spawn_item(entry.kind,Vector2(float(entry.get("x",600)),float(entry.get("y",400))))
		if entity==null: break
		if entity is LabRobot:
			entity.health=float(entry.get("hp",100))
			var saved_active=bool(entry.get("active",false))
			entity.active=saved_active
			entity.tint=Color.from_string(str(entry.get("tint","4ce0bd")),LabArt.TEAL)
			var saved_parts=entry.get("parts",[])
			for i in range(mini(saved_parts.size(),entity.parts.size())):
				apply_body_data(entity.parts[i],saved_parts[i])
				entity.parts[i].tint=entity.tint
				mapping[entity.parts[i].serial]=entity.parts[i]
			var severed=entry.get("severed",[])
			for j_idx in severed:
				var idx=int(j_idx)
				if idx>=0 and idx<entity.joints.size() and is_instance_valid(entity.joints[idx]):
					entity.joints[idx].queue_free()
					entity.joints[idx]=null
			entity.update_part_collisions()
			if not entity.is_part_attached(0) or not entity.is_part_attached(2): entity.health = 0.0
			if entity.health<=0: entity.die()
			var vk=str(entry.get("virus",""))
			if vk in VIRUSES: entity.infect(vk,false)
			if not entity.dead: entity.active=saved_active
			var held_id=int(entry.get("held",0))
			if held_id>0: held_pairs.append([entity,held_id])
		else:
			apply_body_data(entity,entry)
			mapping[entity.serial]=entity
			if entity.kind=="c_motor":
				entity.gear=clampi(int(entry.get("gear",0)),-1,1)
				entity.active=entity.gear!=0
			if entity.kind in VEHICLES:
				entity.gear=int(entry.get("gear",0)) if int(entry.get("gear",0)) in LabVehicle.gears(entity.kind) else 0
				entity.active=entity.gear!=0
				if entity.health<=0: entity.wrecked=true; entity.gear=0; entity.active=false
				LabVehicle.rebuild(self,entity)
	for pair in data.get("links",[]):
		if pair is Array and pair.size()==2 and mapping.has(int(pair[0])) and mapping.has(int(pair[1])):
			make_link(mapping[int(pair[0])],mapping[int(pair[1])])
	for bond in data.get("welds",[]):
		if bond is Array and bond.size()==3 and mapping.has(int(bond[0])) and mapping.has(int(bond[1])) and str(bond[2]) in ["rigid","pivot","motor","spring"]:
			LabParts.weld(self,mapping[int(bond[0])],mapping[int(bond[1])],str(bond[2]))
	for entry in get_tree().get_nodes_in_group("bodies"):
		if entry.kind=="c_motor" and entry.active: LabParts.refresh_motor(self,entry)
	for pair in held_pairs:
		if mapping.has(int(pair[1])): equip_gun(pair[0],mapping[int(pair[1])],false)
	reset_view()

const SOUND_LENGTH = {
	"click":0.1,"spawn":0.1,"hit":0.1,"pulse":0.1,"explosion":0.32,"shot":0.12,"whoosh":0.16,
	"shot_heavy":0.3,"laser":0.24,"zap":0.2,"flame":0.18,"spray":0.16,"thunk":0.13,"rocket":0.42,
	"metal":0.3,"glass":0.4,"wood":0.2,"splash":0.36,"sizzle":0.28,"freeze":0.34,"boing":0.3,
	"snap":0.16,"revive":0.56,"power_down":0.55,"grab":0.05,"drop":0.07,"delete":0.2,"equip":0.16,
	"ignite":0.34,"fizz":0.32,"switch_on":0.13,"switch_off":0.13,"pop":0.1,"chip":0.26,"link":0.18,
	"firework":0.6,"siren":0.62,"rotor":0.13,"horn":0.46
}

func _make_audio() -> void:
	# Все звуки синтезируются на старте: ни одного аудиофайла в сборке.
	for kind in SOUND_LENGTH:
		var seconds: float=SOUND_LENGTH[kind]
		var count=int(22050*seconds)
		var bytes=PackedByteArray()
		bytes.resize(count*2)
		var lp=0.0   # простой ФНЧ для «мягкого» шума
		var lp2=0.0
		var hold=0.0 # для треска: держим случайный уровень несколько сэмплов
		for i in range(count):
			var time=float(i)/22050
			var u=float(i)/count
			var env=pow(1-u,2)
			var noise=randf()*2-1
			lp+=(noise-lp)*0.12
			lp2+=(noise-lp2)*0.03
			var sample=0.0
			match kind:
				"click": sample=sin(time*TAU*720)*0.22
				"spawn": sample=sin(time*TAU*(450+time*3000))*0.2
				"hit": sample=noise*0.3+sin(time*TAU*90)*0.25
				"pulse": sample=sin(time*TAU*(1000-time*7500))*0.3+noise*0.12
				"explosion": sample=noise*0.6+sin(time*TAU*(80-time*120))*0.3
				"shot": sample=noise*0.4+sin(time*TAU*(1600-time*11000))*0.28
				"whoosh": sample=noise*0.24*sin(time*PI/seconds)+sin(time*TAU*(240+time*320))*0.26
				"shot_heavy":
					env=pow(1-u,3)
					sample=lp*1.1+noise*0.22*pow(1-u,8)+sin(time*TAU*(70-time*90))*0.4
				"laser":
					var f=2600.0*pow(0.12,u)
					sample=signf(sin(time*TAU*f))*0.16+sin(time*TAU*f*1.5)*0.12
				"zap":
					if i%int(randf_range(40,260))==0: hold=randf_range(-1,1)
					env=1.0-u
					sample=hold*0.26+signf(sin(time*TAU*120))*0.08+noise*0.1*absf(hold)
				"flame":
					env=sin(u*PI)
					sample=lp*1.4+lp2*1.2
				"spray":
					env=sin(u*PI)*(1-u*0.4)
					sample=(noise-lp)*0.32
				"thunk":
					env=pow(1-u,4)
					sample=sin(time*TAU*(160-time*500))*0.55+noise*0.25*pow(1-u,20)
				"rocket":
					env=minf(u*8,1.0)*(1-u)
					sample=lp*1.3*(0.4+u)+sin(time*TAU*(90+u*140))*0.18
				"metal":
					env=pow(1-u,2.5)
					sample=(sin(time*TAU*523)*0.2+sin(time*TAU*1307)*0.14+sin(time*TAU*2011)*0.1+sin(time*TAU*3163)*0.06)+noise*0.3*pow(1-u,30)
				"glass":
					env=pow(1-u,1.5)
					sample=noise*0.12*pow(1-u,12)
					for k in range(5):
						var at=float(k)*0.055
						if time>at: sample+=sin((time-at)*TAU*(2600+k*530))*0.2*exp(-(time-at)*38)
				"wood":
					env=pow(1-u,3)
					sample=lp*1.1+sin(time*TAU*(190-time*300))*0.35
				"splash":
					env=pow(1-u,1.6)
					sample=lp*1.3+sin(time*TAU*(380+sin(time*TAU*23)*160))*0.1*(1-u)
				"sizzle":
					env=1.0-u*0.7
					if randf()<0.012: hold=1.0
					hold*=0.93
					sample=(noise-lp)*0.16+noise*hold*0.4
				"freeze":
					env=pow(1-u,1.3)
					sample=(sin(time*TAU*(1800+u*1400))*0.12+sin(time*TAU*(2700+u*1800))*0.07)+(noise-lp)*0.1
				"boing":
					env=pow(1-u,1.4)
					sample=sin(time*TAU*(210+sin(time*TAU*18)*70*(1-u)))*0.4
				"snap":
					env=pow(1-u,5)
					sample=noise*0.5+sin(time*TAU*920)*0.3
				"revive":
					env=minf(u*20,1.0)*(1-u)
					var step=mini(int(u*4),3)
					sample=sin(time*TAU*[440.0,554.0,659.0,880.0][step])*0.24+sin(time*TAU*[880.0,1108.0,1318.0,1760.0][step])*0.08
				"power_down":
					env=1-u
					var f=620.0*pow(0.13,u)
					sample=sin(time*TAU*f)*0.28+signf(sin(time*TAU*f*0.5))*0.07
				"grab": sample=sin(time*TAU*1250)*0.18
				"drop": sample=sin(time*TAU*520)*0.2
				"delete":
					sample=sin(time*TAU*(900-u*700))*0.25+noise*0.05
				"equip":
					env=1.0
					sample=noise*0.35*exp(-time*260)+sin(time*TAU*1400)*0.18*exp(-time*90)
					if time>0.07:
						var t2=time-0.07
						sample+=noise*0.3*exp(-t2*260)+sin(t2*TAU*1900)*0.16*exp(-t2*80)
				"ignite":
					env=minf(u*6,1.0)*pow(1-u,1.5)
					sample=lp2*2.2+lp*0.6+sin(time*TAU*85)*0.15
				"fizz":
					env=pow(1-u,1.2)
					sample=(noise-lp2)*0.26
				"switch_on":
					sample=sin(time*TAU*(660.0 if u<0.45 else 990.0))*0.22
				"switch_off":
					sample=sin(time*TAU*(990.0 if u<0.45 else 620.0))*0.22
				"pop":
					env=pow(1-u,6)
					sample=noise*0.7+sin(time*TAU*300)*0.3
				"chip":
					env=1-u*0.6
					sample=signf(sin(time*TAU*[1200.0,1800.0,900.0,2400.0,1500.0][mini(int(u*5),4)]))*0.2
				"link":
					env=pow(1-u,2)
					sample=sin(time*TAU*(240+sin(time*TAU*40)*30))*0.3
				"siren":
					env=minf(u*12,1.0)*minf((1-u)*12,1.0)
					var f=720.0 if int(time/0.155)%2==0 else 960.0
					sample=sin(time*TAU*f)*0.22+signf(sin(time*TAU*f))*0.05
				"rotor":
					env=pow(1-u,3)
					sample=lp2*2.6+sin(time*TAU*55)*0.3
				"horn":
					# Двухтональный автомобильный гудок: большая терция, мягкая атака.
					env=minf(u*30,1.0)*minf((1-u)*9,1.0)
					sample=signf(sin(time*TAU*370))*0.09+signf(sin(time*TAU*466))*0.09+sin(time*TAU*370)*0.1+sin(time*TAU*466)*0.08
				"firework":
					env=minf(u*10,1.0)*(1-u*0.6)
					sample=sin(time*TAU*(900+u*1900))*0.14+(noise-lp)*0.12
			bytes.encode_s16(i*2,int(clampf(sample*env,-1,1)*32767))
		var stream=AudioStreamWAV.new()
		stream.format=AudioStreamWAV.FORMAT_16_BITS
		stream.mix_rate=22050
		stream.data=bytes
		audio[kind]=stream
	for i in range(16):
		var player=AudioStreamPlayer.new()
		world.add_child(player)
		audio_pool.append(player)

var _sound_last: Dictionary={}

func play_sound(kind: String, volume: float=0.3) -> void:
	if muted or get_tree().paused or audio_pool.is_empty() or not audio.has(kind): return
	# Один и тот же звук не чаще раза в 35 мс: горящая груда или очередь
	# минигана иначе забивают все каналы одинаковым щелчком.
	var now=Time.get_ticks_msec()
	if now-int(_sound_last.get(kind,-1000))<35: return
	_sound_last[kind]=now
	var player=audio_pool[audio_index%audio_pool.size()]
	audio_index+=1
	player.stream=audio[kind]
	player.volume_db=linear_to_db(volume)
	player.pitch_scale=randf_range(0.94,1.06)
	player.play()

func gun_sound(kind: String) -> Array:
	match kind:
		"shotgun","sawed","cannon": return ["shot_heavy",0.5]
		"railgun": return ["laser",0.42]
		"rocket_gun": return ["rocket",0.4]
		"crossbow","harpoon","nailgun","disc_gun": return ["thunk",0.36]
		"freezer": return ["freeze",0.3]
		"bouncer": return ["boing",0.3]
		"minigun": return ["shot",0.2]
	return ["shot",0.28]

func _draw_overlay() -> void:
	# 0. Selection tactical holographic brackets
	if is_instance_valid(selected):
		var target_entity = selected.ragdoll if is_instance_valid(selected.ragdoll) else selected
		var center_p: Vector2 = target_entity.global_position
		var box_size: Vector2 = Vector2(50, 70)
		var rot: float = 0.0
		if target_entity is LabRobot:
			box_size = Vector2(48, 86)
			if target_entity.parts.size() > 1 and is_instance_valid(target_entity.parts[1]):
				center_p = target_entity.parts[1].global_position
		elif target_entity is LabBody:
			box_size = target_entity.dimensions + Vector2(16, 16)
			rot = target_entity.rotation
			center_p = target_entity.global_position
		
		var half_w = box_size.x * 0.5
		var half_h = box_size.y * 0.5
		var bracket_len = minf(half_w, half_h) * 0.45
		var pulse = 0.75 + sin(Time.get_ticks_msec() * 0.006) * 0.25
		var sel_color = Color(LabArt.TEAL.r, LabArt.TEAL.g, LabArt.TEAL.b, pulse)
		
		var corners = [
			Vector2(-half_w, -half_h),
			Vector2(half_w, -half_h),
			Vector2(half_w, half_h),
			Vector2(-half_w, half_h)
		]
		for ci in range(4):
			var cp = center_p + corners[ci].rotated(rot)
			var d1 = (corners[(ci + 1) % 4] - corners[ci]).normalized() * bracket_len
			var d2 = (corners[(ci + 3) % 4] - corners[ci]).normalized() * bracket_len
			overlay.draw_line(cp, cp + d1.rotated(rot), sel_color, 2.0, true)
			overlay.draw_line(cp, cp + d2.rotated(rot), sel_color, 2.0, true)
		overlay.draw_circle(center_p, 2.5, sel_color)

	# 1. Energized physical connection conduits (spring links)
	for link in links:
		if is_instance_valid(link.a) and is_instance_valid(link.b):
			var pa = link.a.global_position
			var pb = link.b.global_position
			var dist = pa.distance_to(pb)
			# Outer glow conduit
			overlay.draw_line(pa, pb, Color(0.15, 0.42, 0.46, 0.55), 5.5, true)
			# Core connection line
			overlay.draw_line(pa, pb, LabArt.TEAL, 1.8, true)
			# Animated traveling energy pulse
			if dist > 10:
				var phase = fmod(Time.get_ticks_msec() * 0.0018, 1.0)
				var pulse_pos = pa.lerp(pb, phase)
				overlay.draw_circle(pulse_pos, 4.5, Color(LabArt.TEAL.r, LabArt.TEAL.g, LabArt.TEAL.b, 0.4))
				overlay.draw_circle(pulse_pos, 2.0, Color(1.0, 1.0, 1.0, 0.95))
	
	for w in welds:
		LabParts.draw_weld(overlay,w,(w.a.kind=="c_motor" and w.a.active) or (w.b.kind=="c_motor" and w.b.active) if is_instance_valid(w.a) and is_instance_valid(w.b) else false)
	if is_instance_valid(link_first):
		overlay.draw_dashed_line(link_first.global_position, cursor, LabArt.TEAL, 2.2, 8.0)
		overlay.draw_circle(link_first.global_position, 6.0, Color(LabArt.TEAL.r, LabArt.TEAL.g, LabArt.TEAL.b, 0.35))
	
	# 2. Military tactical laser aiming sight with holographic reticle
	var gun = aimed_weapon()
	if is_instance_valid(gun):
		var direction = Vector2.RIGHT.rotated(gun.rotation)
		var muzzle = gun.global_position + direction * (gun.dimensions.x * 0.52)
		var distance = muzzle.distance_to(cursor)
		if distance > 12:
			# Tapered laser beam with bloom glow
			overlay.draw_line(muzzle, cursor, Color(0.25, 1.0, 0.78, 0.12), 7.0, true)
			overlay.draw_line(muzzle, cursor, Color(0.45, 1.0, 0.85, 0.85), 1.6, true)
			overlay.draw_line(muzzle, cursor, Color(1.0, 1.0, 1.0, 0.9), 0.75, true)
			
			# Animated holographic targeting reticle at cursor
			var time_tick = Time.get_ticks_msec() * 0.004
			var radius = 10.5 + sin(time_tick * 2.0) * 1.5
			# Rotating outer reticle ring with tick marks
			overlay.draw_arc(cursor, radius, 0, TAU, 32, Color(0.45, 1.0, 0.84, 0.90), 1.5, true)
			overlay.draw_arc(cursor, radius + 5.0, time_tick, time_tick + 1.2, 12, Color(0.45, 1.0, 0.84, 0.55), 1.5, true)
			overlay.draw_arc(cursor, radius + 5.0, time_tick + PI, time_tick + PI + 1.2, 12, Color(0.45, 1.0, 0.84, 0.55), 1.5, true)
			
			# Pinpoint crosshairs
			for axis in [Vector2.RIGHT, Vector2.DOWN]:
				overlay.draw_line(cursor - axis * 3.0, cursor - axis * 12.0, LabArt.TEAL, 1.4, true)
				overlay.draw_line(cursor + axis * 3.0, cursor + axis * 12.0, LabArt.TEAL, 1.4, true)
			overlay.draw_circle(cursor, 1.8, Color(1.0, 1.0, 1.0, 0.95))
	
	# 3. Physics drag line and tether indicator
	if is_instance_valid(dragging):
		var anchor = dragging.to_global(drag_offset)
		overlay.draw_line(anchor, cursor, Color(0.2, 0.85, 1.0, 0.25), 4.0, true)
		overlay.draw_line(anchor, cursor, Color(0.45, 1.0, 0.9, 0.9), 1.5, true)
		overlay.draw_circle(cursor, 5.5, LabArt.TEAL, false, 1.8)
		overlay.draw_circle(cursor, 2.0, Color(1.0, 1.0, 1.0, 0.95))
		if dragging.kind in VIRUSES:
			var host = nearest_robot(dragging.global_position, 100)
			if host: overlay.draw_arc(host.parts[1].global_position, 30, 0, TAU, 32, host.virus_color() if host.virus != "" else LabArt.TEAL, 1.8)
		elif can_hold(dragging.kind):
			var robot = nearest_robot(dragging.global_position)
			if robot: overlay.draw_arc(robot.parts[6].global_position, 24, 0, TAU, 32, LabArt.TEAL, 1.8)
	
	# 4. In-world tools and placement reticles
	if not menu_open and not help_open and not hud.blocks(get_viewport().get_mouse_position()):
		if placing:
			LabArt.icon(overlay, spawn_kind, cursor, 0.85, Color(0.35, 1.0, 0.78, 0.85), placing_rotation)
			var t_rot = Time.get_ticks_msec() * 0.002
			overlay.draw_arc(cursor, 38, t_rot, t_rot + PI * 1.5, 48, Color(0.35, 1.0, 0.78, 0.45), 1.5)
			overlay.draw_arc(cursor, 38, t_rot + PI * 1.7, t_rot + TAU, 16, Color(0.35, 1.0, 0.78, 0.25), 1.0)
			if placing_rotation != 0.0:
				overlay.draw_line(cursor, cursor + Vector2.RIGHT.rotated(placing_rotation) * 44.0, LabArt.AMBER, 1.6, true)
				overlay.draw_circle(cursor + Vector2.RIGHT.rotated(placing_rotation) * 44.0, 2.5, LabArt.AMBER)
		elif tool in ["pulse", "blast"]:
			var rad = 20.0 if tool == "pulse" else 44.0
			var t_rot = Time.get_ticks_msec() * 0.003
			overlay.draw_arc(cursor, rad, 0, TAU, 52, LabArt.AMBER, 1.4)
			overlay.draw_arc(cursor, rad + 6.0, t_rot, t_rot + 0.8, 12, Color(LabArt.AMBER.r, LabArt.AMBER.g, LabArt.AMBER.b, 0.5), 1.5)
			overlay.draw_arc(cursor, rad + 6.0, t_rot + PI, t_rot + PI + 0.8, 12, Color(LabArt.AMBER.r, LabArt.AMBER.g, LabArt.AMBER.b, 0.5), 1.5)
			overlay.draw_line(cursor - Vector2(7, 0), cursor + Vector2(7, 0), LabArt.AMBER, 1.2)
			overlay.draw_line(cursor - Vector2(0, 7), cursor + Vector2(0, 7), LabArt.AMBER, 1.2)

func _visual_mobile() -> void:
	# Phone layout with the catalog open and an item picked, which is where the
	# purpose text has to land without a hover to rely on.
	hud.resized.emit()
	catalog_open=true
	catalog_category=3
	placing=true
	spawn_kind="magnet"
	await get_tree().create_timer(1.0,true).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/%s-catalog.png" % ("mobile" if mobile else "desktop"))
	catalog_category=0
	spawn_kind="robot_titan"
	await get_tree().create_timer(0.5,true).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/%s-robots.png" % ("mobile" if mobile else "desktop"))
	print("VISUAL_MOBILE_OK")
	get_tree().quit()

func _visual_vehicles() -> void:
	# Панель машины: ряд передач, второе действие с полоской перезарядки,
	# буксир трактора и трос вертолёта.
	hud.resized.emit()
	clear_scene()
	catalog_open=false
	var truck=spawn_item("car_monster",Vector2(560,FLOOR_Y-110))
	var tractor=spawn_item("car_tractor",Vector2(960,FLOOR_Y-110))
	spawn_item("crate",Vector2(830,FLOOR_Y-24))
	var heli=spawn_item("car_heli",Vector2(260,FLOOR_Y-300))
	spawn_item("crate",Vector2(260,FLOOR_Y-24))
	LabVehicle.set_gear(heli,2)
	LabVehicle.use_ability(self,heli)
	await get_tree().create_timer(1.6).timeout
	LabVehicle.use_ability(self,tractor)
	LabVehicle.set_gear(truck,1)
	LabVehicle.use_ability(self,truck)
	select(truck)
	await get_tree().create_timer(0.3,true).timeout
	await RenderingServer.frame_post_draw
	var prefix="mobile" if mobile else "desktop"
	get_viewport().get_texture().get_image().save_png("res://artifacts/%s-vehicle-truck.png" % prefix)
	# Грузовик уехал бы в трактор до второго снимка.
	remove_entity(truck)
	select(heli)
	await get_tree().create_timer(0.4,true).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/%s-vehicle-heli.png" % prefix)
	print("VISUAL_VEHICLES_OK")
	get_tree().quit()

func _visual_damage() -> void:
	# One robot per condition band so the four damage stages can be compared.
	clear_scene()
	catalog_open=false
	var levels=[1.0,0.62,0.32,0.10]
	var crew=[]
	for i in range(levels.size()):
		crew.append(spawn_item("robot",Vector2(460.0+float(i)*155.0,FLOOR_Y-4)))
	# Let them settle on their feet first, then damage and pin them, so the
	# plating is readable instead of face down on the slab.
	await get_tree().create_timer(1.6).timeout
	user_paused=true
	_update_pause()
	for i in range(crew.size()):
		crew[i].hurt(crew[i].max_health*(1.0-levels[i]))
	camera_center=Vector2(692,545)
	camera.zoom=Vector2.ONE*1.85
	await get_tree().create_timer(0.6,true).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/damage.png")
	print("VISUAL_DAMAGE_OK")
	get_tree().quit()

func _visual_toys() -> void:
	clear_scene()
	# Physics stays live and the toys are dropped onto the slab: art that
	# overhangs its collision box only shows up once the toy is resting.
	for i in range(TOYS.size()):
		spawn_item(TOYS[i],Vector2(300+float(i)*118.0,540))
	camera.zoom=Vector2.ONE*1.15
	placing=true
	spawn_kind="cork"
	await get_tree().create_timer(3.0).timeout
	user_paused=true
	_update_pause()
	for shot in range(4):
		camera_center=Vector2(760+float(shot)*1170.0,470)
		await get_tree().create_timer(0.6,true).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://artifacts/toys-%d.png" % shot)
	print("VISUAL_TOYS_OK count=",TOYS.size())
	get_tree().quit()

func _visual_scenes() -> void:
	# Renders every backdrop to artifacts/ so the 21 themes can be reviewed
	# side by side after art changes.
	for entry in SCENES:
		build_scene(str(entry[0]))
		await get_tree().create_timer(0.35,true).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://artifacts/scenes/scene-%s.png" % str(entry[0]))
	print("VISUAL_SCENES_OK count=",SCENES.size())
	get_tree().quit()

func _visual_test() -> void:
	await get_tree().create_timer(2.5,true).timeout
	await RenderingServer.frame_post_draw
	var path="res://artifacts/items.png" if catalog_category>0 else "res://artifacts/gameplay.png"
	get_viewport().get_texture().get_image().save_png(path)
	print("VISUAL_TEST_OK bodies=",get_tree().get_nodes_in_group("bodies").size())
	get_tree().quit()

func _run_smoke_test() -> void:
	menu_open=false
	_update_pause()
	var catalog_seen: Dictionary={}
	for cat in CATALOG:
		assert(cat.size()==4 and cat[3] is Array and not cat[3].is_empty(),"Catalog category structure")
		for kind in cat[3]:
			assert(kind in ITEMS,"Catalog kind is spawnable: "+str(kind))
			assert(not catalog_seen.has(kind),"Catalog kind unique: "+str(kind))
			catalog_seen[kind]=true
	assert(catalog_seen.size()==ITEMS.size(),"Catalog lists every item")
	# Вкладки каталога перечислены в hud.gd вручную: категория, забытая там,
	# существует в данных, но недоступна игроку.
	var tabs: Array=[]
	for tab_i in hud.CATEGORY_ROW_TOP+hud.CATEGORY_ROW_BOTTOM: tabs.append(int(tab_i))
	tabs.sort()
	assert(tabs.size()==CATALOG.size(),"Every catalog category has a tab")
	for tab_i in range(CATALOG.size()): assert(tabs[tab_i]==tab_i,"Catalog tabs cover every category exactly once")
	await get_tree().create_timer(2.0).timeout
	assert(get_tree().get_nodes_in_group("robots").size()==2,"Two robots must spawn")
	for b in get_tree().get_nodes_in_group("bodies"):
		assert(is_finite(b.global_position.x) and is_finite(b.global_position.y),"Physics must remain finite")
	var support=spawn_item("plank",Vector2(250,440))
	support.freeze=true
	var dead_robot=spawn_item("robot",Vector2(250,426))
	dead_robot.hurt(1000)
	# Wait for physical rest, which depends on the landing pose. A three-second
	# timeout used to pass by forcibly freezing a corpse that was still moving.
	for _step in range(80):
		await get_tree().create_timer(0.1).timeout
		if dead_robot.corpse_settled: break
	assert(dead_robot.dead and dead_robot.health==0,"Robot death state")
	assert(dead_robot.corpse_settled,"Dead robot must settle instead of convulsing")
	var supported_height=dead_robot.parts[1].global_position.y
	remove_entity(support)
	await get_tree().create_timer(0.8).timeout
	assert(dead_robot.parts[1].global_position.y>supported_height+12,"Dead robot must fall when its support disappears")
	var a=spawn_item("metal",Vector2(440,350),true)
	var b=spawn_item("thruster",Vector2(510,350),true)
	make_link(a,b,true)
	select(a)
	freeze_selected()
	assert(a.freeze,"Freeze tool")
	freeze_selected()
	select(b)
	activate_selected()
	assert(b.active,"Thruster activation")
	save_snapshot()
	var count=get_tree().get_nodes_in_group("bodies").size()
	var snapshot=cached_scene.duplicate(true)
	restore_snapshot(snapshot)
	assert(get_tree().get_nodes_in_group("bodies").size()==count,"Save/load body count")
	assert(links.size()==1,"Save/load links")
	var barrel=spawn_item("barrel",Vector2(1150,450))
	barrel.damage(200,Vector2.ZERO)
	await get_tree().create_timer(0.4).timeout
	assert(not is_instance_valid(barrel),"Barrel must explode")
	assert(int(stats.get("explosion",0))>0,"Explosion event")
	user_paused=true
	_update_pause()
	var probe=get_tree().get_nodes_in_group("bodies")[0]
	var before=probe.global_position
	await get_tree().create_timer(0.2,true).timeout
	assert(probe.global_position.distance_to(before)<0.1,"Pause stops simulation")
	user_paused=false
	_update_pause()
	build_scene("chain")
	explode(Vector2(420,590),230,1)
	await get_tree().create_timer(3).timeout
	assert(int(stats.get("explosion",0))>=5,"Chain reaction propagates")
	action("clear_scene")
	assert(get_tree().get_nodes_in_group("bodies").is_empty(),"Clear scene action cleans all bodies")
	var test_box = spawn_item("crate", Vector2(500, 500))
	select(test_box)
	action("clone")
	assert(get_tree().get_nodes_in_group("bodies").size() == 2, "Clone duplicates selected entity")
	action("clear_scene")
	var new_items: Dictionary={}
	for i in range(GADGETS.size()):
		var kind=GADGETS[i]
		new_items[kind]=spawn_item(kind,Vector2(260+i*80,300))
	assert(new_items.size()==10,"Ten interactive items must be available")
	assert(new_items.balloon.gravity_factor<0,"Balloon buoyancy")
	assert(new_items.weight.mass>=40,"Heavy weight")
	assert(new_items.bumper.physics_material_override.bounce>0.9,"Bouncy bumper")
	for kind in ["magnet","fan","coil","wheel"]:
		select(new_items[kind])
		activate_selected()
		assert(new_items[kind].active,"Active mechanism: "+kind)
	await get_tree().create_timer(0.25).timeout
	assert(absf(new_items.wheel.angular_velocity)>0.1,"Motor wheel torque")
	assert(new_items.balloon.linear_velocity.y<0,"Balloon rises")
	assert(new_items.fan.health<new_items.fan.max_health,"Tesla coil discharge")
	new_items.glass.damage(100,Vector2.ZERO)
	await get_tree().create_timer(0.2).timeout
	assert(not is_instance_valid(new_items.glass),"Fragile glass")
	clear_scene()
	var variants: Array=[]
	for i in range(1,ROBOTS.size()): variants.append(spawn_item(ROBOTS[i],Vector2(180+i*95,616)))
	assert(variants.size()==10 and get_tree().get_nodes_in_group("robots").size()==10,"Ten additional robot variants")
	assert(variants[1].max_health>=250 and variants[1].parts[1].mass>6,"Titan armor and mass")
	assert(variants[7].parts[1].gravity_factor<1,"Antigrav robot")
	for index in [0,2,3,4,6,8,9]:
		variants[index].toggle_active()
		assert(variants[index].active,"Robot ability activation")
	await get_tree().create_timer(0.15).timeout
	assert(variants[2].parts[1].linear_velocity.y<0,"Jumper ability")
	assert(variants[4].ability_cooldown>0,"Sparkbot discharge cycle")
	save_snapshot(false)
	restore_snapshot(cached_scene.duplicate(true))
	var restored_variants=get_tree().get_nodes_in_group("robots")
	assert(restored_variants.size()==10,"Robot variants survive save and load")
	assert(restored_variants.any(func(r): return r.variant=="robot_runner" and r.active),"Robot ability state survives save and load")
	clear_scene()
	var bomber=spawn_item("robot_bomber",Vector2(600,616))
	var bomb_target=spawn_item("robot_titan",Vector2(690,616))
	bomber.toggle_active()
	await get_tree().create_timer(1.0).timeout
	assert(bomber.dead and is_instance_valid(bomb_target),"Bomber stalks and detonates near a target")
	clear_scene()
	var auto_bot=spawn_item("robot_tesla",Vector2(430,FLOOR_Y-4))
	var auto_enemy=spawn_item("robot_titan",Vector2(760,FLOOR_Y-4))
	var auto_pistol=spawn_item("pistol",Vector2(468,535))
	auto_bot.toggle_active()
	await get_tree().create_timer(1.0).timeout
	assert(is_instance_valid(auto_bot.held_gun) and auto_bot.held_gun==auto_pistol,"Autonomous robot picks up a nearby weapon")
	await get_tree().create_timer(0.8).timeout
	assert(auto_bot.ai_state in ["advance","space","attack","retreat","armed","guard"],"Autonomous robot enters combat behavior")
	assert(is_instance_valid(auto_enemy),"Autonomous target remains valid")
	clear_scene()
	var life_medic=spawn_item("robot_medic",Vector2(420,FLOOR_Y-4))
	var life_patient=spawn_item("robot_scout",Vector2(700,FLOOR_Y-4))
	life_patient.hurt(25)
	life_medic.toggle_active()
	await get_tree().create_timer(0.35).timeout
	assert(life_medic.ai_state=="rescue" and life_medic.social_target==life_patient,"Medic seeks a wounded robot")
	var life_guard=spawn_item("robot_titan",Vector2(900,FLOOR_Y-4))
	life_guard.toggle_active()
	await get_tree().create_timer(0.35).timeout
	assert(life_guard.ai_state in ["escort","guard_patrol"],"Titan performs guardian duty")
	clear_scene()
	var shooter=spawn_item("robot",Vector2(520,FLOOR_Y-4))
	var guns: Dictionary={}
	for i in range(WEAPONS.size()):
		guns[WEAPONS[i]]=spawn_item(WEAPONS[i],Vector2(280+i*48,500))
	assert(guns.size()==WEAPONS.size() and guns.values().all(func(g): return g!=null),"All firearms must spawn")
	var pistol=guns.pistol
	# Catalog spawning is checked; keep the aiming fixture free of loose guns
	# spawned through the shooter's body and of their collision impulses.
	for g in guns.values():
		if g != pistol: remove_entity(g)
	assert(equip_gun(shooter,pistol,false),"Robot takes a pistol")
	assert(shooter.held_gun==pistol and pistol.holder==shooter,"Gun is held")
	select(shooter.parts[1])
	cursor=shooter.palm()+Vector2(260,-110)
	for i in range(8): shooter.hold_weapon_pose(0.05)
	var expected_aim=(cursor-shooter.palm()).angle()
	assert(absf(wrapf(pistol.rotation-expected_aim,-PI,PI))<0.12,"Held firearm aims at the cursor")
	select(null)
	await get_tree().create_timer(0.35).timeout
	var palm=shooter.palm()
	var grip_pt=pistol.global_position+pistol.grip_local.rotated(pistol.rotation)
	assert(palm.distance_to(grip_pt)<12.0,"Grip stays firmly in the palm")
	assert(absf(shooter.parts[0].angular_velocity)<8.0,"Aiming does not spin the robot head")
	var aim_dir=Vector2.RIGHT.rotated(pistol.rotation)
	assert(aim_dir.x>0.5,"Barrel points away from the body")
	for g in guns.values():
		if g!=pistol and is_instance_valid(g):
			g.global_position=Vector2(-500,200)
			g.linear_velocity=Vector2.ZERO
	var muzzle=pistol.global_position+aim_dir*(pistol.dimensions.x*0.52)
	var dest=muzzle+aim_dir*280
	dest.y=clampf(dest.y,180.0,FLOOR_Y-28.0)
	var target=spawn_item("crate",dest)
	var hp0=target.health
	select(shooter.parts[1])
	activate_selected()
	assert(pistol.mechanism_cooldown>0,"Pistol cooldown after firing")
	await get_tree().create_timer(0.4).timeout
	var slugs=0
	for body in get_tree().get_nodes_in_group("bodies"):
		if body.kind=="slug": slugs+=1
	assert(slugs>0 or not is_instance_valid(target) or target.health<hp0,"Shot interacts with the world")
	save_snapshot(false)
	restore_snapshot(cached_scene.duplicate(true))
	var restored_shooter: LabRobot
	for robot in get_tree().get_nodes_in_group("robots"):
		if robot.variant=="robot": restored_shooter=robot
	assert(is_instance_valid(restored_shooter) and is_instance_valid(restored_shooter.held_gun),"Held gun survives save and load")
	assert(restored_shooter.held_gun.kind=="pistol","Restored gun kind")
	restored_shooter.drop_gun()
	assert(not is_instance_valid(restored_shooter.held_gun),"Gun can be dropped")
	clear_scene()
	var ng=spawn_item("nailgun",Vector2(500,500))
	fire_weapon(ng)
	await get_tree().create_timer(0.2).timeout
	assert(get_tree().get_nodes_in_group("bodies").any(func(b): return b.kind=="nail"),"Nailgun fires nails")
	clear_scene()
	var tur=spawn_item("turret",Vector2(640,590))
	spawn_item("crate",Vector2(900,594))
	tur.active=true
	await get_tree().create_timer(0.6).timeout
	assert(tur.active and (tur.mechanism_cooldown>0 or get_tree().get_nodes_in_group("bodies").any(func(b): return b.kind=="slug")),"Turret fires")
	var nade=spawn_item("grenade",Vector2(400,400))
	nade.active=true
	nade.mechanism_cooldown=0.05
	await get_tree().create_timer(0.55).timeout
	assert(not is_instance_valid(nade),"Grenade detonates")
	clear_scene()
	var drone=spawn_item("drone",Vector2(720,560))
	assert(drone and drone.gravity_factor<1,"Drone is light")
	drone.active=true
	await get_tree().create_timer(0.4).timeout
	assert(is_instance_valid(drone) and (drone.global_position.y<548 or drone.linear_velocity.y<0),"Drone lifts off")
	var flak=spawn_item("flak",Vector2(480,500))
	flak.rotation=0
	drone.global_position=Vector2(700,500)
	drone.linear_velocity=Vector2.ZERO
	fire_weapon(flak)
	assert(flak.mechanism_cooldown>0,"Flak gun fires")
	await get_tree().create_timer(0.55).timeout
	assert(get_tree().get_nodes_in_group("bodies").any(func(b): return b.kind=="emp") or not is_instance_valid(drone) or drone.health<drone.max_health,"Anti-drone charge seeks drones")
	clear_scene()
	var blades: Dictionary={}
	for i in range(MELEE.size()):
		blades[MELEE[i]]=spawn_item(MELEE[i],Vector2(300+i*70,500))
	assert(blades.size()==MELEE.size() and blades.values().all(func(g): return g!=null),"Melee weapons must spawn")
	# Проверка появления сделана — груду убираем. Робот, стоящий в куче из
	# пятнадцати клинков, расшвыривает их ногами и получает порезы от каждого;
	# дальше проверяется удар, а не выживание в мясорубке.
	for blade_kind in blades:
		if blade_kind!="sword" and is_instance_valid(blades[blade_kind]): remove_entity(blades[blade_kind])
	await get_tree().create_timer(0.2).timeout
	var fighter=spawn_item("robot",Vector2(620,FLOOR_Y-4))
	assert(equip_gun(fighter,blades.sword,false),"Robot takes a sword")
	var dummy=spawn_item("crate",Vector2(700,594))
	var dummy_hp=dummy.health
	var dummy_x=dummy.global_position.x
	fire_weapon(blades.sword)
	assert(blades.sword.mechanism_cooldown>0,"Sword swing")
	assert(fighter.act=="slash","Fighter initiates sword slash animation")
	await get_tree().create_timer(0.08).timeout
	assert(fighter.act=="slash" and fighter.act_time>0,"Sword is actively winding up during attack")
	await get_tree().create_timer(0.32).timeout
	assert(not is_instance_valid(dummy) or dummy.health < dummy_hp, "Melee strike deals direct damage to target")
	# 75 пикселей — это внутри бойца: роботы порождались внахлёст, расталкивание
	# отшвыривало атакующего за спину цели, и удар уходил в пустоту.
	var target_bot = spawn_item("robot", Vector2(790, FLOOR_Y-4))
	await get_tree().create_timer(0.3).timeout
	var bot_hp0 = target_bot.health
	blades.sword.mechanism_cooldown = 0
	fire_weapon(blades.sword)
	await get_tree().create_timer(0.35).timeout
	assert(target_bot.health < bot_hp0, "Melee strike hits and damages enemy robot")
	# Test hammer launching target flying away ("с молотом улетает")
	# Use a fresh pair: the previous victim and dropped sword can collide
	# with the attacker and stun it before this independent hammer strike.
	clear_scene()
	fighter=spawn_item("robot",Vector2(620,FLOOR_Y-4))
	var hammer = spawn_item("hammer", Vector2(520, FLOOR_Y-40))
	assert(equip_gun(fighter, hammer, false),"Robot takes the hammer")
	assert(fighter.held_gun==hammer,"Hammer is in the working hand")
	var flying_bot = spawn_item("robot", Vector2(fighter.parts[1].global_position.x+130, FLOOR_Y-4))
	await get_tree().create_timer(0.3).timeout
	var flying_x0 = flying_bot.parts[1].global_position.x
	fire_weapon(hammer)
	await get_tree().create_timer(0.35).timeout
	var flying_x1 = flying_bot.parts[1].global_position.x
	var flying_vx = flying_bot.parts[1].linear_velocity.x
	assert(flying_x1 > flying_x0 + 40.0 or flying_vx > 200.0, "Hammer launch sends target flying away")
	assert(fighter.is_on_floor() and absf(fighter.parts[1].linear_velocity.y) < 160.0, "Attacker stays grounded and stable on the floor")
	clear_scene()
	var exotic_ok=0
	for i in range(EXOTIC.size()):
		if spawn_item(EXOTIC[i],Vector2(220+i*42,420)): exotic_ok+=1
	assert(exotic_ok==EXOTIC.size(),"Exotic weapons spawn")
	var rail=spawn_item("railgun",Vector2(500,300))
	fire_weapon(rail)
	assert(rail.mechanism_cooldown>0,"Railgun fires")
	var saw=spawn_item("chainsaw",Vector2(600,300))
	fire_weapon(saw)
	assert(saw.active,"Chainsaw revs")
	clear_scene()
	var host=spawn_item("robot",Vector2(600,FLOOR_Y-4))
	var chip=spawn_item("virus_dance",Vector2(640,580))
	assert(chip and chip.kind in VIRUSES,"Virus chip spawns")
	assert(infect_robot(host,chip,false),"Virus installs safely")
	assert(host.virus=="virus_dance" and host.active,"Dance behavior is on")
	assert(chip.is_queued_for_deletion(),"Chip is consumed")
	save_snapshot(false)
	restore_snapshot(cached_scene.duplicate(true))
	var restored_host: LabRobot
	for robot in get_tree().get_nodes_in_group("robots"):
		if robot.variant=="robot": restored_host=robot
	assert(is_instance_valid(restored_host) and restored_host.virus=="virus_dance","Virus survives save and load")
	restored_host.purge_virus()
	assert(restored_host.virus=="","Virus can be cleared")
	clear_scene()
	var rub=spawn_item("rubber",Vector2(400,400))
	assert(rub and rub.physics_material_override.bounce>0.8,"Rubber bounces")
	var anv=spawn_item("anvil",Vector2(500,400))
	assert(anv.mass>=60,"Anvil is heavy")
	var conv=spawn_item("conveyor",Vector2(600,400))
	select(conv)
	activate_selected()
	assert(conv.active,"Conveyor toggles")
	var crys=spawn_item("crystal",Vector2(700,400))
	crys.damage(100,Vector2.ZERO)
	await get_tree().create_timer(0.25).timeout
	assert(not is_instance_valid(crys),"Crystal shatters")
	build_scene("rink")
	assert(arena.theme=="ice","Rink uses ice backdrop")
	assert(get_tree().get_nodes_in_group("bodies").any(func(b): return b.kind=="ice"),"Rink has ice")
	build_scene("factory")
	assert(arena.theme=="factory","Factory backdrop")
	assert(get_tree().get_nodes_in_group("bodies").any(func(b): return b.kind=="conveyor" and b.active),"Factory conveyor runs")
	assert(SCENES.size()==26,"Twenty-six start scenes")
	# Новые сцены на стихиях: вода выталкивает, батарея питает цепь.
	build_scene("flood")
	assert(get_tree().get_nodes_in_group("bodies").any(func(b): return b.kind=="water_pool"),"Flood has water")
	assert(get_tree().get_nodes_in_group("bodies").any(func(b): return b.kind=="gas_can"),"Flood has a fuel can")
	build_scene("circuit")
	assert(get_tree().get_nodes_in_group("bodies").any(func(b): return b.kind=="battery"),"Circuit has a battery")
	assert(links.size()>=2,"Circuit is pre-wired")
	build_scene("dojo")
	assert(arena.theme=="dojo","Dojo backdrop")
	assert(get_tree().get_nodes_in_group("robots").size()==2,"Dojo has two robots")
	assert(get_tree().get_nodes_in_group("bodies").any(func(b): return b.kind=="sword"),"Dojo has a sword")
	build_scene("span")
	assert(arena.theme=="canyon","Span uses canyon backdrop")
	assert(get_tree().get_nodes_in_group("bodies").any(func(b): return b.kind=="glass"),"Span has glass")
	build_scene("bath")
	assert(arena.theme=="bath" and arena.floor_body.physics_material_override.friction<0.08,"Bath floor is slippery")
	build_scene("pinball")
	assert(arena.theme=="arcade","Pinball backdrop")
	assert(get_tree().get_nodes_in_group("bodies").any(func(b): return b.kind=="bumper"),"Pinball has bumpers")
	build_scene("relay")
	assert(arena.theme=="track","Relay backdrop")
	assert(get_tree().get_nodes_in_group("bodies").any(func(b): return b.kind=="boost_pad" and b.active),"Relay boosters run")
	clear_scene()
	var test_bot=spawn_item("robot",Vector2(500,FLOOR_Y-4))
	var c4_bomb=spawn_item("c4",Vector2(520,FLOOR_Y-4))
	assert(is_instance_valid(c4_bomb),"C4 spawns")
	var s_life=spawn_item("syringe_life",Vector2(500,FLOOR_Y-40))
	assert(is_instance_valid(s_life),"Syringe spawns")
	test_bot.dismember_joint(4)
	assert(not is_instance_valid(test_bot.joints[4]),"Shoulder joint severed")
	test_bot.die()
	assert(test_bot.dead,"Robot dies")
	test_bot.revive()
	assert(not test_bot.dead and test_bot.health==test_bot.max_health,"Robot revives with 100% health")
	var laser=spawn_item("laser_cutter",Vector2(400,FLOOR_Y-20))
	var sing=spawn_item("singularity",Vector2(600,FLOOR_Y-20))
	assert(is_instance_valid(laser) and is_instance_valid(sing),"Laser and Singularity spawn")
	# --- Стихии -----------------------------------------------------------
	clear_scene()
	spawn_item("water_pool",Vector2(600,FLOOR_Y-60))
	var swim_light=spawn_item("crate",Vector2(590,FLOOR_Y-190))
	var swim_heavy=spawn_item("lead",Vector2(650,FLOOR_Y-190))
	await get_tree().create_timer(3.2).timeout
	var surface=FLOOR_Y-120.0
	assert(is_instance_valid(swim_light) and swim_light.global_position.y<surface+26.0,"Wooden crate floats on water")
	assert(is_instance_valid(swim_heavy) and swim_heavy.global_position.y>surface+50.0,"Lead sinks in water")
	assert(swim_light.wet>0.0,"Floating body gets wet")
	clear_scene()
	var kindling=spawn_item("crate",Vector2(400,FLOOR_Y-26))
	var neighbour=spawn_item("crate",Vector2(446,FLOOR_Y-26))
	var fireproof=spawn_item("metal",Vector2(760,FLOOR_Y-22))
	await get_tree().create_timer(0.5).timeout
	kindling.ignite(1.0,6.0)
	assert(kindling.burning>0.0,"Wood catches fire")
	# Переход огня вероятностный: шанс разыгрывается раз в 0.22 с. За четыре
	# секунды это полтора десятка попыток, и о переходе говорит либо текущее
	# пламя, либо копоть — она остаётся даже если ящик уже прогорел.
	await get_tree().create_timer(4.0).timeout
	assert(not is_instance_valid(neighbour) or neighbour.burning>0.0 or neighbour.scorch>0.0,"Fire spreads to touching wood")
	assert(fireproof.burning<=0.0,"Metal does not burn")
	if is_instance_valid(neighbour):
		neighbour.douse(1.0)
		assert(neighbour.burning<=0.0,"Foam puts fire out")
	clear_scene()
	var cell=spawn_item("battery",Vector2(400,FLOOR_Y-18))
	var wire=spawn_item("cable",Vector2(500,FLOOR_Y-14))
	var conductor=spawn_item("metal",Vector2(600,FLOOR_Y-22))
	var insulator=spawn_item("rubber",Vector2(700,FLOOR_Y-24))
	make_link(cell,wire)
	make_link(wire,conductor)
	make_link(conductor,insulator)
	cell.active=true
	await get_tree().create_timer(1.2).timeout
	assert(wire.charge>0.2,"Current reaches the cable")
	assert(conductor.charge>0.1,"Current reaches metal through a link")
	assert(insulator.charge<=0.0,"Rubber does not conduct")
	# Машины: колёса на подвеске, мотор везёт, после сохранения и загрузки
	# шарниры снова держат колёса, а не отпускают их в корпус.
	for car_kind in VEHICLES:
		clear_scene()
		var car=spawn_item(car_kind,Vector2(300,FLOOR_Y-90))
		assert(car!=null and car.wheels.size()==LabVehicle.spec(car_kind).wheels.size(),"Vehicle spawns with wheels: "+car_kind)
		await get_tree().create_timer(1.4).timeout
		for wi in range(car.wheels.size()):
			var sag=car.to_local(car.wheels[wi].global_position)-LabVehicle.spec(car_kind).wheels[wi][0]
			assert(absf(sag.x)<3.0 and absf(sag.y)<8.0,"Wheel rides on its suspension: "+car_kind)
		var start_x=car.global_position.x
		var start_y=car.global_position.y
		select(car)
		activate_selected()
		if car_kind=="car_heli":
			assert(car.gear==2,"F makes the helicopter hover")
			await get_tree().create_timer(2.0).timeout
			assert(start_y-car.global_position.y>150.0,"Helicopter climbs to altitude")
			activate_selected()
			await get_tree().create_timer(1.0).timeout
			assert(car.global_position.x-start_x>120.0,"Helicopter flies forward")
			activate_selected(); activate_selected()
			await get_tree().create_timer(3.0).timeout
			assert(car.global_position.y>start_y-40.0,"Helicopter lands on stop")
		else:
			assert(car.gear==1,"F puts the vehicle in gear")
			await get_tree().create_timer(1.2).timeout
			assert(car.global_position.x-start_x>minf(120.0,float(LabVehicle.spec(car_kind).speed)*0.5),"Vehicle drives forward: "+car_kind)
			activate_selected()
			await get_tree().create_timer(2.0).timeout
			assert(car.linear_velocity.x<-20.0,"Reverse gear drives backwards: "+car_kind)
			activate_selected()
		assert(absf(wrapf(car.rotation,-PI,PI))<0.5,"Vehicle stays upright: "+car_kind)
		save_snapshot(false)
		restore_snapshot(cached_scene)
		await get_tree().create_timer(1.0).timeout
		var loaded=get_tree().get_nodes_in_group("bodies").filter(func(b): return b.kind==car_kind)
		assert(loaded.size()==1,"Vehicle survives save and load: "+car_kind)
		var reloaded=loaded[0]
		assert(reloaded.wheels.size()==LabVehicle.spec(car_kind).wheels.size(),"Loaded vehicle rebuilds its wheels: "+car_kind)
		assert(absf(wrapf(reloaded.rotation,-PI,PI))<0.3,"Loaded vehicle does not flip: "+car_kind)
		for wi in range(reloaded.wheels.size()):
			var sag=reloaded.to_local(reloaded.wheels[wi].global_position)-LabVehicle.spec(car_kind).wheels[wi][0]
			assert(absf(sag.y)<8.0,"Loaded wheel stays on its suspension: "+car_kind)
		# Удаление любой части убирает машину целиком; у вертолёта колёс нет.
		remove_entity(reloaded.wheels[0] if not reloaded.wheels.is_empty() else reloaded)
		await get_tree().process_frame
		assert(get_tree().get_nodes_in_group("bodies").filter(func(b): return not b.is_queued_for_deletion() and (b.kind==car_kind or b.kind==LabVehicle.WHEEL)).is_empty(),"Deleting a wheel removes the whole vehicle")
		assert(LabVehicle.ability(car_kind)!="","Every vehicle has a V action: "+car_kind)
		assert("V " in str(ITEM_ABOUT[car_kind][0]) and "V " in str(ITEM_ABOUT[car_kind][1]),"Catalog text names the V action: "+car_kind)
	# Действия машин: передача кнопкой, второе действие по V у каждого типа.
	var count_kind=func(k: String) -> int: return get_tree().get_nodes_in_group("bodies").filter(func(b): return b.kind==k and not b.is_queued_for_deletion()).size()
	clear_scene()
	var sedan=spawn_item("car_sedan",Vector2(300,FLOOR_Y-90))
	await get_tree().create_timer(1.0).timeout
	select(sedan.wheels[0])
	set_selected_gear(-1)
	assert(sedan.gear==-1 and sedan.active,"Gear button selects reverse directly, even from a wheel")
	set_selected_gear(2)
	assert(sedan.gear==-1,"A car has no hover gear")
	set_selected_gear(0)
	assert(sedan.gear==0 and not sedan.active,"Gear button stops the car")
	assert(LabVehicle.use_ability(self,sedan),"Horn sounds")
	assert(sedan.ability_cooldown>0.0 and not LabVehicle.use_ability(self,sedan),"The V action has a cooldown")
	select(sedan.wheels[1])
	duplicate_selected()
	await get_tree().process_frame
	assert(count_kind.call("car_sedan")==2 and count_kind.call(LabVehicle.WHEEL)==4,"Cloning from a wheel copies the whole car, not a loose wheel")
	clear_scene()
	var truck=spawn_item("car_monster",Vector2(300,FLOOR_Y-110))
	var racer=spawn_item("car_sport",Vector2(900,FLOOR_Y-80))
	var tank=spawn_item("car_tank",Vector2(1500,FLOOR_Y-80))
	await get_tree().create_timer(1.4).timeout
	var truck_y=truck.global_position.y
	assert(LabVehicle.use_ability(self,truck),"Monster truck jumps from the ground")
	await get_tree().create_timer(0.25).timeout
	assert(truck_y-truck.global_position.y>40.0,"The jump lifts the truck")
	assert(not LabVehicle.use_ability(self,truck),"No second jump mid-air")
	assert(LabVehicle.use_ability(self,racer) and racer.boost>0.0,"Nitro fires")
	await get_tree().create_timer(0.6).timeout
	assert(racer.linear_velocity.x>250.0,"Nitro pushes the car even in neutral")
	var balls=count_kind.call("cannonball")
	assert(LabVehicle.use_ability(self,tank) and count_kind.call("cannonball")==balls+1,"Tank fires on command while parked")
	assert(not LabVehicle.use_ability(self,tank),"Tank cannon reloads")
	clear_scene()
	var apc=spawn_item("car_apc",Vector2(300,FLOOR_Y-90))
	var firetruck=spawn_item("car_fire",Vector2(900,FLOOR_Y-90))
	await get_tree().create_timer(1.0).timeout
	assert(LabVehicle.use_ability(self,apc) and count_kind.call("slug")==6,"APC fires a six-round burst")
	assert(LabVehicle.use_ability(self,firetruck) and count_kind.call("foam")>=10,"Fire engine sprays a foam volley without a fire")
	clear_scene()
	var medic=spawn_item("car_ambulance",Vector2(300,FLOOR_Y-90))
	var patient=spawn_item("robot",Vector2(470,FLOOR_Y-4))
	var cop=spawn_item("car_police",Vector2(1300,FLOOR_Y-90))
	var suspect=spawn_item("robot",Vector2(1120,FLOOR_Y-4))
	await get_tree().create_timer(1.0).timeout
	patient.health=patient.max_health*0.4
	assert(LabVehicle.use_ability(self,medic) and patient.health>=patient.max_health,"Ambulance repairs a nearby robot on command")
	assert(LabVehicle.use_ability(self,cop) and suspect.stun>=2.9,"Police arrest works behind the car too")
	clear_scene()
	var pickup=spawn_item("car_pickup",Vector2(300,FLOOR_Y-90))
	var dozer=spawn_item("car_dozer",Vector2(1000,FLOOR_Y-90))
	await get_tree().create_timer(1.0).timeout
	assert(not LabVehicle.use_ability(self,pickup),"Dumping an empty bed does nothing")
	var cargo=spawn_item("crate",pickup.global_transform*Vector2(-44,-30))
	var rubble=spawn_item("crate",dozer.global_transform*Vector2(150,-10))
	await get_tree().create_timer(0.8).timeout
	assert(LabVehicle.use_ability(self,pickup) and LabVehicle.use_ability(self,dozer),"Dump and shove fire")
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert(cargo.linear_velocity.y<-150.0,"Dump throws the load out of the bed")
	assert(rubble.linear_velocity.x>200.0,"The blade shoves what is in front")
	clear_scene()
	var tractor=spawn_item("car_tractor",Vector2(500,FLOOR_Y-110))
	var trailer=spawn_item("crate",Vector2(380,FLOOR_Y-24))
	var heli=spawn_item("car_heli",Vector2(1200,FLOOR_Y-300))
	var load_box=spawn_item("crate",Vector2(1200,FLOOR_Y-24))
	LabVehicle.set_gear(heli,2)
	assert(LabVehicle.use_ability(self,heli) and LabVehicle.hooked(self,heli),"Helicopter winch hooks the crate below")
	await get_tree().create_timer(1.0).timeout
	assert(LabVehicle.use_ability(self,tractor) and LabVehicle.hooked(self,tractor),"Tractor hitches the crate behind")
	await get_tree().create_timer(2.0).timeout
	assert(load_box.global_position.y<FLOOR_Y-80.0,"The winch lifts its load")
	save_snapshot(false)
	restore_snapshot(cached_scene)
	await get_tree().process_frame
	assert(links.size()==2,"Tow and winch ropes survive save and load")
	tractor=get_tree().get_nodes_in_group("bodies").filter(func(b): return b.kind=="car_tractor")[0]
	assert(LabVehicle.use_ability(self,tractor) and not LabVehicle.hooked(self,tractor) and links.size()==1,"Unhitch drops only the tractor rope")
	# Конструктор: каждая деталь появляется; «Связь» сваривает намертво;
	# шарнир вращается; мотор крутит; сварка переживает сохранение.
	clear_scene()
	for part_kind in PARTS:
		var piece=spawn_item(part_kind,Vector2(400,300))
		assert(piece!=null and piece.get_children().any(func(n): return n is CollisionShape2D),"Builder part spawns with a shape: "+part_kind)
		remove_entity(piece)
	await get_tree().process_frame
	var beam_a=spawn_item("c_beam_long",Vector2(400,FLOOR_Y-200))
	var beam_b=spawn_item("c_beam",Vector2(545,FLOOR_Y-200))
	assert(LabParts.weld(self,beam_a,beam_b),"Link welds two builder parts")
	assert(welds.size()==1 and welds[0].type=="rigid","Plain parts weld rigidly")
	var rel0=beam_b.global_position-beam_a.global_position
	await get_tree().create_timer(1.5).timeout
	var rel1=(beam_b.global_position-beam_a.global_position).rotated(-beam_a.rotation+0.0)
	assert(absf(wrapf(beam_b.rotation-beam_a.rotation,-PI,PI))<0.06 and absf(rel1.length()-rel0.length())<4.0,"Welded parts move as one body")
	save_snapshot(false)
	restore_snapshot(cached_scene)
	await get_tree().process_frame
	assert(welds.size()==1 and welds[0].type=="rigid","Welds survive save and load")
	clear_scene()
	var base=spawn_item("c_block",Vector2(500,FLOOR_Y-220))
	base.freeze=true
	var motor=spawn_item("c_motor",Vector2(500,FLOOR_Y-220))
	var arm=spawn_item("c_beam",Vector2(572,FLOOR_Y-220))
	assert(LabParts.weld(self,motor,base) and welds[-1].type=="rigid","A motor mounts rigidly first")
	assert(LabParts.weld(self,motor,arm) and welds[-1].type=="motor","A motor drives the next part")
	select(motor)
	activate_selected()
	await get_tree().create_timer(1.0).timeout
	assert(absf(arm.angular_velocity)>2.0,"The motor spins the attached part")
	activate_selected(); activate_selected()
	assert(motor.gear==0,"F cycles the motor back to stop")
	clear_scene()
	var post=spawn_item("c_block",Vector2(500,FLOOR_Y-220))
	post.freeze=true
	var hinge=spawn_item("c_hinge",Vector2(522,FLOOR_Y-220))
	var door=spawn_item("c_beam",Vector2(570,FLOOR_Y-220))
	LabParts.weld(self,hinge,post)
	assert(LabParts.weld(self,hinge,door) and welds[-1].type=="pivot","A hinge lets the next part swing")
	await get_tree().create_timer(1.0).timeout
	assert(door.global_position.y>FLOOR_Y-205.0,"A door on a hinge swings down under gravity")
	remove_entity(hinge)
	await get_tree().process_frame
	assert(welds.is_empty(),"Deleting a part removes its welds")
	clear_scene()
	print("SMOKE_TEST_OK save_load freeze links thruster pause chain_reaction guns bodies=",get_tree().get_nodes_in_group("bodies").size())
	get_tree().quit()
