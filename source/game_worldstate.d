module gen_repl.game_worldstate;

import std.algorithm;
import std.array;
import std.json;
import std.random;
import std.stdio;
import std.string;

import gen_repl.game_objects;

class WorldState {
    bool isGameOver;
    string playerName;
    Creature[] creatures;
    Item[] items;
    Location[] map;

public:
    // Constructors
    this(bool isGameOver, string playerName) {
        this.isGameOver = isGameOver;
        this.playerName = playerName;
    }

    // Getter and Setter methods for private members
    bool getIsGameOver() {
        return isGameOver;
    }

    void setIsGameOver(bool isGameOver) {
        this.isGameOver = isGameOver;
    }

    string getPlayerName() {
        return playerName;
    }

    void setPlayerName(string playerName) {
        this.playerName = playerName;
    }

    // Function to randomly populate items and/or creatures in locations
    void populateMap() {
        auto rnd = Random(42);
        // Tracks the items and creatures that have been added
        Item[] addedItems;
        Creature[] addedCreatures;
        while ((addedItems.length < items.length || addedCreatures.length < creatures.length) && map.length > 0) {
            foreach (ref location; map) {
                // Randomly add items
                if (uniform(0, 10, rnd) % 2 == 0) {
                    // Add a random item from the items array if not already added
                    Item[] remainingItems = items.filter!(item => !addedItems.canFind(item)).array();
                    if (!remainingItems.empty()) {
                        auto randomItem = remainingItems.choice(rnd);
                        addedItems ~= randomItem;
                        location.items ~= randomItem;
                    }
                }

                // Randomly add creatures
                if (uniform(0, 10, rnd) % 2 == 0) {
                    // Add a random creature from the creatures array if not already added
                    Creature[] remainingCreatures = creatures.filter!(creature => !addedCreatures.canFind(creature)).array();
                    if (!remainingCreatures.empty()) {
                        auto randomCreature = remainingCreatures.choice(rnd);
                        addedCreatures ~= randomCreature;
                        location.creatures ~= randomCreature;
                    }
                }
            }
        }
    }
}
