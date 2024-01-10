module gen_repl.game_data;

const string itemsJSON = `[
    {"name": "Java Dagger", "description": "A dagger with Java syntax engraved."},
    {"name": "Agile Throwing Star", "description": "Throw it with the speed of an agile sprint."},
    {"name": "CSS Whip", "description": "A whip made of cascading style sheets."},
    {"name": "Marketing Spellbook", "description": "Unleashes the power of persuasive marketing spells."},
    {"name": "JavaScript Staff", "description": "A staff infused with the chaotic energy of JavaScript."},
    {"name": "Debugging Grenade", "description": "Throws a grenade that explodes into debugging tools."},
    {"name": "Caffeine Sword", "description": "A sword forged from the pure essence of caffeine."},
    {"name": "HTML Shield", "description": "A shield made of HTML elements for front-end defense."},
    {"name": "JIRA Boomerang", "description": "Throws a boomerang that always comes back with more tasks."},
    {"name": "SQL Scroll of Querying", "description": "Unrolls a scroll with powerful SQL queries."},
]`;

const string creaturesJSON = `[
    {
        "name": "Code Gremlin",
        "description": "A mischievous creature that wreaks havoc in your code.",
        "health": 120,
        "defense": 10,
        "attack": 20,
        "inventory": [{"name": "Syntax Error Scroll", "description": "Unleashes confusing syntax errors on your foes."}]
    },
    {
        "name": "Buzzword Banshee",
        "description": "A spectral being that haunts your meetings with buzzwords.",
        "health": 140,
        "defense": 12,
        "attack": 22,
        "inventory": [{"name": "Marketing Jargon Shield", "description": "Deflects buzzwords with a touch of sarcasm."}]
    },
    {
        "name": "Coffee Zombie",
        "description": "A creature fueled by decaf, spreading lethargy in its wake.",
        "health": 130,
        "defense": 11,
        "attack": 21,
        "inventory": [{"name": "Decaf Dagger", "description": "Strikes fear into the hearts of caffeine lovers."}]
    },
    {
        "name": "Project Manager Ogre",
        "description": "A massive ogre that thrives on project timelines and Gantt charts.",
        "health": 180,
        "defense": 18,
        "attack": 28,
        "inventory": [{"name": "Gantt Chart Shield", "description": "Blocks your progress with strategic planning."}]
    }]`;

const string locationsJSON = `[
    {
        "name": "Your Desk",
        "description": "A cubicle filled with comics and despair.",
        "exits": ["Meeting Room", "Kitchen"]
    },
    {
        "name": "Meeting Room",
        "description": "Where dreams of productivity go to die.",
        "exits": ["Your Desk", "Bathroom"]
    },
    {
        "name": "Kitchen",
        "description": "The sacred ground of caffeine worship and snack rituals.",
        "exits": ["Your Desk", "Break Room"]
    },
    {
        "name": "Bathroom",
        "description": "A place for hiding from work and doom-scrolling.",
        "exits": ["Meeting Room"]
    },
    {
        "name": "Break Room",
        "description": "Escape here for a brief moment of sanity.",
        "exits": ["Kitchen"]
    },
    {
        "name": "Server Room Dungeon",
        "description": "Navigate through cables and server racks in this mysterious dungeon.",
        "exits": ["Meeting Room"]
    },
    {
        "name": "Boss's Lair",
        "description": "Enter at your own risk. The lair of the ultimate decision-maker.",
        "exits": ["Bathroom", "Server Room Dungeon"]
    }
]`;
