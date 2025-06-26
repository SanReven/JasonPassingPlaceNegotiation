package example;

// Environment code for project simpleppapp

import jason.asSyntax.*;
import jason.environment.*;
//import jason.asSyntax.parser.*;

import jason.environment.grid.GridWorldModel;
import jason.environment.grid.GridWorldView;
import jason.environment.grid.Location;

//import java.text.ParseException;
//import java.util.logging.*;

import java.awt.event.KeyEvent;
import java.awt.event.KeyListener;
import java.util.Dictionary;

//import static java.lang.Math.abs;

import java.util.HashMap;

//import javax.swing.JFrame;
//import javax.swing.JLabel;
//import javax.swing.border.EtchedBorder;

import java.awt.Color;
import java.awt.Font;
import java.awt.Graphics;
//import java.awt.Image;
//import java.util.Random;
import java.util.logging.Logger;
//import javax.swing.ImageIcon;

//import java.util.ArrayList;

public class Env extends Environment {

    //-----AGENT PART------
    private Logger logger = Logger.getLogger("Jason Passing Place App."+Env.class.getName());

    private int worldOption;
    private int nbOfAgents;
    private RoadModel model;
    private RoadView view;

    private HashMap<String, Integer> agentNameIdDict = new HashMap<String, Integer>();
    private HashMap<Integer, String> agentNameIdInverse = new HashMap<Integer, String>();

    

    public static final int RoadSize = 13; // Road size
    public static final int ROAD = 16; //To determine where there is road.
    public static final int PASS = 32; //To determine where there is passing place.

    public int pasID = 0; //number of passing places

    public enum Direct {
        //Change to lowercase if agents are not happy storing full caps.
        up, right, left, down
    }


    

    /** Called before the MAS execution with the args informed in .mas2j */
    public void init(String[] args) {
        worldOption = Integer.parseInt(args[0]);
        nbOfAgents = Integer.parseInt(args[1]);
        model = new RoadModel(worldOption, nbOfAgents);
        view  = new RoadView(model);
        model.setView(view);
        updatePercepts();

        view.addKeyListener(new KeyListener() {

            @Override
            public void keyPressed(KeyEvent e) {
                //logger.info("KEY PRESSED");
                if(agentNameIdDict.containsKey("player")) {
                    int agID = agentNameIdDict.get("player");
                    int keyPressed = e.getKeyCode();
                    Location agLoc = model.getAgPos(agID);
    
                    //Player always facing right.
                    //Currently using setAgPos all over to make less calculations.
                    //Code adapted from: https://stackoverflow.com/questions/10876491/how-to-use-keylistener (User Abhishek Choudhary)
                    switch(keyPressed) {
                        case KeyEvent.VK_RIGHT:
                            if (model.hasObject(PASS, agLoc)) {
                                if(model.hasObject(ROAD, agLoc.x + 1, agLoc.y - 1) && model.getAgAtPos(agLoc.x + 1, agLoc.y - 1) == -1) {
                                    model.setAgPos(agID, agLoc.x + 1, agLoc.y - 1);
                                } else if (model.hasObject(ROAD, agLoc.x + 1, agLoc.y + 1) && model.getAgAtPos(agLoc.x + 1, agLoc.y + 1) == -1) {
                                    model.setAgPos(agID, agLoc.x + 1, agLoc.y + 1);
                                } else {
                                    logger.info("PATH BLOCKED");
                                }
                            } else {
                                if(model.getAgAtPos(agLoc.x + 1, agLoc.y) == -1) {
                                    //addPercept("player", Literal.parseLiteral("input_go_forward"));
                                    model.setAgPos(agID, agLoc.x + 1, agLoc.y);
                                } else {
                                    logger.info("PATH BLOCKED");
                                }
                            }
                            break;
                        case KeyEvent.VK_LEFT:
                        if (model.hasObject(PASS, agLoc)) {
                            if(model.hasObject(ROAD, agLoc.x - 1, agLoc.y - 1) && model.getAgAtPos(agLoc.x - 1, agLoc.y - 1) == -1) {
                                model.setAgPos(agID, agLoc.x - 1, agLoc.y - 1);
                            } else if (model.hasObject(ROAD, agLoc.x - 1, agLoc.y + 1) && model.getAgAtPos(agLoc.x - 1, agLoc.y + 1) == -1) {
                                model.setAgPos(agID, agLoc.x - 1, agLoc.y + 1);
                            } else {
                                logger.info("PATH BLOCKED");
                            }
                        } else {
                            if(model.getAgAtPos(agLoc.x - 1, agLoc.y) == -1) {
                                //addPercept("player", Literal.parseLiteral("input_go_backward));
                                model.setAgPos(agID, agLoc.x - 1, agLoc.y);
                            } else {
                                logger.info("PATH BLOCKED");
                            }
                        }
                        break;
                        case KeyEvent.VK_UP:
                            //Can only go into PASS if before or after it. A car can't slide sideways.
                            Location forwardUP = new Location(agLoc.x + 1, agLoc.y - 1);
                            Location backwardUP = new Location(agLoc.x - 1, agLoc.y - 1);
                            if(model.hasObject(PASS, forwardUP) && model.getAgAtPos(forwardUP) == -1) {
                                //addPercept("player", Literal.parseLiteral("input_pull_in(" forward.x + "," + forward.y + ")"));
                                model.setAgPos(agID, agLoc.x + 1, agLoc.y - 1);
                            } else if (model.hasObject(PASS, backwardUP) && model.getAgAtPos(backwardUP) == -1){
                                //addPercept("player", Literal.parseLiteral("input_pull_in(" backward.x + "," + backward.y + ")"));
                                model.setAgPos(agID, agLoc.x - 1, agLoc.y - 1);
                            } else {
                                logger.info("NO AVAILABLE PASSING PLACE");
                            }
                            break;
                        case KeyEvent.VK_DOWN:
                            Location forwardDOWN = new Location(agLoc.x + 1, agLoc.y + 1);
                            Location backwardDOWN = new Location(agLoc.x - 1, agLoc.y + 1);
                            if(model.hasObject(PASS, forwardDOWN) && model.getAgAtPos(forwardDOWN) == -1) {
                                //addPercept("player", Literal.parseLiteral("input_pull_in(" forward.x + "," + forward.y + ")"));
                                model.setAgPos(agID, agLoc.x + 1, agLoc.y + 1);
                            } else if (model.hasObject(PASS, backwardDOWN) && model.getAgAtPos(backwardDOWN) == -1) {
                                //addPercept("player", Literal.parseLiteral("input_pull_in(" backward.x + "," + backward.y + ")"));
                                model.setAgPos(agID, agLoc.x - 1, agLoc.y + 1);
                            } else {
                                logger.info("NO AVAILABLE PASSING PLACE");
                            }
                            break;
                        default:
                            logger.info("NOT VALID KEY. USE ARROW KEYS");
                            break;
                    }
                } else {
                    logger.info("NO PLAYER AGENT FOUND");
                }
            }

            @Override
            public void keyReleased(KeyEvent e) {
                ;
            }

            @Override
            public void keyTyped(KeyEvent e) {
                ;
            }
        });
    

    }

    //Duplicate without parsing until we get parsing working
    @Override
    public boolean executeAction(String agName, Structure action) {
        logger.info("Agent " + agName + " executing: " + action);
        try {
            if (action.getFunctor().equals("move_forward")) {
                //logger.info("action received");
                Direct facing = Direct.valueOf((action.getTerm(0)).toString());
                //logger.info("Direction converted: " + facing);
                model.moveForward(agName, facing);
            } else if (action.getFunctor().equals("move_backward")) {
                //Turn the direction to the opposite
                Direct facing = Direct.valueOf((action.getTerm(0)).toString());
                //Quick and dirty implementation for now
                if(facing == Direct.right) {
                    facing = Direct.left;
                } else {
                    facing = Direct.right;
                }
                model.moveForward(agName, facing);
            } else if (action.getFunctor().equals("check_ahead")) {
                Direct facing = Direct.valueOf((action.getTerm(1)).toString());
                int dist = (int)((NumberTerm)action.getTerm(0)).solve();
                checkAhead(agName, dist, facing);
            } else if (action.getFunctor().equals("check_behind")) {
                //Turn the direction to the opposite
                int dist = (int)((NumberTerm)action.getTerm(0)).solve();
                Direct facing = Direct.valueOf((action.getTerm(1)).toString());
                checkBehind(agName, dist, facing);
            } else if (action.getFunctor().equals("pullin")) {
                int x = (int)((NumberTerm)action.getTerm(0)).solve();
                int y = (int)((NumberTerm)action.getTerm(1)).solve();
                Location passLoc = new Location(x,y);
                logger.info("PASSING PLACE Location: " + passLoc);
                model.moveTo(agName,passLoc);
            } else if (action.getFunctor().equals("pullout")) {
                Direct facing = Direct.valueOf((action.getTerm(0)).toString());
                pullOut(agName, facing);
            } else if (action.getFunctor().equals("look_around")) {
                Direct facing = Direct.valueOf((action.getTerm(1)).toString());
                int dist = (int)((NumberTerm)action.getTerm(0)).solve();
                //lookAround(agName, dist, facing);
            } else if (action.getFunctor().equals("remove_me")) {
                //Temporary graveyard/completion area for agents that have run to completion and reached the end of the road.
                Location finished = new Location(0,0);
                model.moveTo(agName,finished);
            } else {
                return false;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        updatePercepts();

        try {
            Thread.sleep(200);
        } catch (Exception e) {}
        informAgsEnvironmentChanged();
        return true;
    }


    /** creates the agents perception based on the the road */
    //We might not need this at all
    void updatePercepts() {
        for (String agName : agentNameIdDict.keySet()) {
            int agID = agentNameIdDict.get(agName);

            //clearPercepts(agName);

            Location agLoc = model.getAgPos(agID);

            Literal pos = Literal.parseLiteral("pos(" + agName + "," + agLoc.x + "," + agLoc.y + ")");

            addPercept(agName, pos);

            if(model.hasObject(PASS, agLoc.x, 0)) {
                Literal pass = Literal.parseLiteral("last_pass(" + agLoc.x + "," + agLoc.y + ",free," + "has_pass(left)" + ")");
                addPercept(agName, pass);
            } else if (model.hasObject(PASS, agLoc.x, 2)){
                Literal pass = Literal.parseLiteral("last_pass(" + agLoc.x + "," + agLoc.y + ",free," + "has_pass(right)" + ")");
                addPercept(agName, pass);
            }
        }
    }

    /** Called before the end of MAS execution */
    @Override
    public void stop() {
        super.stop();
    }

    public void checkAhead(String agName, int viewDist, Direct facing) throws Exception {
        Location agLoc = model.getAgPos(agentNameIdDict.get(agName));
        
        clearPercepts(agName);
        int coef = 1;

        if (facing == Direct.left) {
            coef = -1;
        }


        for (int i = 1; i < viewDist + 1; i++) {
            checkLocation(agLoc.x + (coef * i), agLoc.y, agName, coef);
            checkLocation(agLoc.x + (coef * i), agLoc.y + 1, agName, coef);
            checkLocation(agLoc.x + (coef * i), agLoc.y - 1, agName, coef);
        }
    }

    public void checkBehind(String agName, int viewDist, Direct facing) throws Exception {
        Location agLoc = model.getAgPos(agentNameIdDict.get(agName));
        
        clearPercepts(agName);
        int coef = 1;

        if (facing == Direct.right) {
            coef = -1;
        }

        for (int i = 1; i < viewDist + 1; i++) {
            checkLocation(agLoc.x + coef, agLoc.y, agName, (coef * (-1)));
            checkLocation(agLoc.x + coef, agLoc.y + 1, agName, (coef * (-1)));
            checkLocation(agLoc.x + coef, agLoc.y - 1, agName, (coef * (-1)));
        }
    }

    public void checkLocation(int x, int y, String agName, int directionCoef) throws Exception {
        //logger.info("checking position (" + x + "," + y + ")");

        boolean agentFound = false;

        String tempPercept = "";

        String pass;
        String occupied;

        pass = "none";
        occupied = "free";

        int otherAg = model.getAgAtPos(x, y);

        //If there is an agent there
        if (otherAg >= 0) {
            //RETURN HERE. 
            occupied = "occupied(" + agentNameIdInverse.get(otherAg) + ")";
            agentFound = true;
        }

        if (model.hasObject(ROAD, x, y)) {
            int tempLocLeftY = y - directionCoef;
            int tempLocRightY = y + directionCoef;
            if (model.hasObject(PASS, x, tempLocLeftY)) {
                pass = "has_pass(left)";
            } else if (model.hasObject(PASS, x, tempLocRightY)) {
                pass = "has_pass(right)";
            }
            Literal road = Literal.parseLiteral("road(" + x + "," + y + "," + occupied + "," + pass + ")");
            addPercept(agName, road);
            //logger.info(road.toString());
        } else if (model.hasObject(PASS, x, y)) {
            //If facing left, a pass on the left should be (2 + (- 1)). If facing right, a pass on the left should be (0 + 1).
            if ((y + directionCoef) == 1) {
                pass = "left";
            } else {
                pass = "right";
            }

            Literal road = Literal.parseLiteral("pass(" + x + "," + y + "," + occupied + "," + pass + ")");
            addPercept(agName, road);
            //logger.info(road.toString());
        } else {
            ;
            //Add no percept for now.
        }
    }

    /*public void lookAround(String agName, int viewDist, Direct facing) {
        Location agLoc = model.getAgPos(agentNameIdDict.get(agName));
        
        clearPercepts(agName);
        int coef = 1;

        if (facing == Direct.right) {
            coef = -1;
        }

        for (int i = 1; i < viewDist + 1; i++) {
            checkLocation(agLoc.x + coef, agLoc.y, agName, (coef * (-1)));
            checkLocation(agLoc.x + coef, agLoc.y + 1, agName, (coef * (-1)));
            checkLocation(agLoc.x + coef, agLoc.y - 1, agName, (coef * (-1)));
        
            checkLocation(agLoc.x - coef, agLoc.y, agName, (coef * (-1)));
            checkLocation(agLoc.x - coef, agLoc.y + 1, agName, (coef * (-1)));
            checkLocation(agLoc.x - coef, agLoc.y - 1, agName, (coef * (-1)));
        }
    }*/

    public void pullOut(String agName, Direct facing) throws Exception {
        clearPercepts(agName);
        updatePercepts();
        int coef = 1;
        int agID = agentNameIdDict.get(agName);
        Location agLoc = model.getAgPos(agID);

        if (facing == Direct.left) {
            coef = -1;
        }

        Location roadLoc = agLoc;

        //Start at 0 and end at 2, so we deduct 1 before we check y axis.
        for(int i = 0; i < 3; i ++){
            int x = agLoc.x + coef;
            int y = agLoc.y + i - 1;
            if (model.hasObject(ROAD, x, y)) {
                roadLoc = new Location(x,y);
            }
        }
        model.moveTo(agName, roadLoc);
    }
    

    //----------WORLD BUILDING PART----------
    class RoadModel extends GridWorldModel {
        private RoadModel(int worldType, int agNumber) {
            super(RoadSize, 3, agNumber);

            // initial location of agents and Passing places based on world type

            switch(worldType) {
                //Q4 Scenario. 2 Cars, PASS in middle to left of d1.
                case 1:
                    addDriver(0, 0, 1, "driver1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driver2", Direct.left);
                    add(PASS, RoadSize/2, 0);
                    break;
                //EXTRA Scenario. 2 Cars, PASS behind to left of d1.
                case 2:
                    addDriver(0, 0, 1, "driver1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driver2", Direct.left);
                    add(PASS, 2, 0);
                    break;
                //Q5 Scenario. 2 Cars, PASS behind to right of d1.
                case 3:
                    addDriver(0, 0, 1, "driver1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driver2", Direct.left);
                    add(PASS, 2, 2);
                    break;
                //Q6 Scenario. 2 Cars, PASS behind to left of d2. d2 CAN reverse.
                case 4:
                    addDriver(0, 0, 1, "driver1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driver2", Direct.left);
                    add(PASS, 10, 2);
                    break;
                //EXTRA Scenario. 2 Cars, PASS behind to left of d1 AND PASS behind to the right of d2.
                case 5:
                    addDriver(0, 0, 1, "driver1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driver2", Direct.left);
                    add(PASS, 10, 0);
                    add(PASS, 2, 0);
                    break;
                //EXTRA Scenario. 2 Cars, no PASS.
                case 6:
                    addDriver(0, 0, 1, "driver1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driver2", Direct.left);
                    break;
                //EXTRA Scenario. 3 Cars, PASS in middle to left of d1, extra car behind d2.
                case 7:
                    addDriver(0, 0, 1, "driver1", Direct.right);
                    addDriver(1, RoadSize - 3, 1, "driver2", Direct.left);
                    addDriver(2, RoadSize - 1, 1, "driver3", Direct.left);
                    add(PASS, RoadSize/2, 0);
                    break;
                //Q7 Scenario. 3 Cars, PASS in middle to right of d1, extra car behind d2.
                case 8:
                    addDriver(0, 0, 1, "driver1", Direct.right);
                    addDriver(1, RoadSize - 3, 1, "driver2", Direct.left);
                    addDriver(2, RoadSize - 1, 1, "driver3", Direct.left);
                    add(PASS, RoadSize/2, 2);
                    break;
                //Q9 Scenario: 3 Cars, PASS behind to left of d1, extra car behind d1.
                case 9:
                    addDriver(0, 2, 1, "driver1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driver2", Direct.left);
                    addDriver(2, 0, 1, "driver3", Direct.right);
                    add(PASS, 2, 0);
                    break;
                //EXTRA Scenario: 3 cars, PASS in middle to the left of d1 AND behind to the left of d1 AND behind to the left of d2, extra car behind d1.
                case 10:
                    addDriver(0, 2, 1, "driver1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driver2", Direct.left);
                    addDriver(2, 0, 1, "driver3", Direct.right);
                    add(PASS, 5, 0);
                    add(PASS, 3, 0);
                    add(PASS, 9, 2);
                    break;
                //Q8 Scenario: 4 Cars, PASS in middle to right of d1.
                case 11:
                    addDriver(0, 2, 1, "driver1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driver2", Direct.left);
                    addDriver(2, 0, 1, "driver3", Direct.right);
                    addDriver(3, RoadSize - 3, 1, "driver4", Direct.left);
                    add(PASS, RoadSize/2, 2);
                    break;
                //EXTRA Scenario: 4 Cars, PASS in middle to right of d1 AND behind to the left of d1 AND behind to the left of d3.
                case 12:
                    addDriver(0, 2, 1, "driver1", Direct.right);
                    addDriver(1, RoadSize - 3, 1, "driver2", Direct.left);
                    addDriver(2, 0, 1, "driver3", Direct.right);
                    addDriver(3, RoadSize - 1, 1, "driver4", Direct.left);
                    add(PASS, RoadSize/2, 0);
                    add(PASS, 2, 0);
                    add(PASS, 10, 2);
                    break;
                //Q8 Scenario: 6 Cars, PASS in middle to right of d1.
                case 13:
                    addDriver(0, 0, 1, "driver1", Direct.right);
                    addDriver(1, 2, 1, "driver2", Direct.right);
                    addDriver(2, 4, 1, "driver3", Direct.right);
                    addDriver(5, RoadSize - 5, 1, "driver4", Direct.left);
                    addDriver(4, RoadSize - 3, 1, "driver5", Direct.left);
                    addDriver(3, RoadSize - 1, 1, "driver6", Direct.left);
                    add(PASS, RoadSize/2, 2);
                    break;
                //EXTRA Scenario: 6 Cars, PASS in middle to right of d1 AND behind to the left of d1 AND behind to the left of d4.
                case 14:
                    addDriver(0, 0, 1, "driver1", Direct.right);
                    addDriver(1, 2, 1, "driver2", Direct.right);
                    addDriver(2, 4, 1, "driver3", Direct.right);
                    addDriver(5, RoadSize - 5, 1, "driver4", Direct.left);
                    addDriver(4, RoadSize - 3, 1, "driver5", Direct.left);
                    addDriver(3, RoadSize - 1, 1, "driver6", Direct.left);
                    add(PASS, RoadSize/2, 2);
                    add(PASS, 3, 0);
                    add(PASS, 10, 2);
                    break;
                //SCENARIOS WITH HUMAN CONTROLLED AGENT. D1 IS REPLACED BY Player
                //Q4 Scenario. 2 Cars, PASS in middle to left of d1.
                case 101:
                    addDriver(0, 0, 1, "player", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driver", Direct.left);
                    add(PASS, RoadSize/2, 0);
                    break;
                //EXTRA Scenario. 2 Cars, PASS behind to left of d1.
                case 102:
                    addDriver(0, 0, 1, "player", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driver", Direct.left);
                    add(PASS, 2, 0);
                    break;
                //Q5 Scenario. 2 Cars, PASS behind to right of d1.
                case 103:
                    addDriver(0, 0, 1, "player", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driver", Direct.left);
                    add(PASS, 2, 2);
                    break;
                //Q6 Scenario. 2 Cars, PASS behind to left of d2. d2 CAN reverse.
                case 104:
                    addDriver(0, 0, 1, "player", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driver", Direct.left);
                    add(PASS, 10, 2);
                    break;
                //EXTRA Scenario. 2 Cars, PASS behind to left of d1 AND PASS behind to the right of d2.
                case 105:
                    addDriver(0, 0, 1, "player", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driver", Direct.left);
                    add(PASS, 10, 0);
                    add(PASS, 2, 0);
                    break;
                //EXTRA Scenario. 2 Cars, no PASS.
                case 106:
                    addDriver(0, 0, 1, "player", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driver", Direct.left);
                    break;
                //EXTRA Scenario. 3 Cars, PASS in middle to left of d1, extra car behind d2.
                case 107:
                    addDriver(0, 0, 1, "player", Direct.right);
                    addDriver(1, RoadSize - 3, 1, "driver1", Direct.left);
                    addDriver(2, RoadSize - 1, 1, "driver2", Direct.left);
                    add(PASS, RoadSize/2, 0);
                    break;
                //Q7 Scenario. 3 Cars, PASS in middle to right of d1, extra car behind d2.
                case 108:
                    addDriver(0, 0, 1, "player", Direct.right);
                    addDriver(1, RoadSize - 3, 1, "driver1", Direct.left);
                    addDriver(2, RoadSize - 1, 1, "driver2", Direct.left);
                    add(PASS, RoadSize/2, 2);
                    break;
                //Q9 Scenario: 3 Cars, PASS behind to left of d1, extra car behind d1.
                case 109:
                    addDriver(0, 4, 1, "player", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driver1", Direct.left);
                    addDriver(2, 2, 1, "driver2", Direct.right);
                    add(PASS, 3, 0);
                    break;
                //EXTRA Scenario: 3 cars, PASS in middle to the left of d1 AND behind to the left of d1 AND behind to the left of d2, extra car behind d1.
                case 110:
                    addDriver(0, 4, 1, "player", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driver1", Direct.left);
                    addDriver(2, 2, 1, "driver2", Direct.right);
                    add(PASS, RoadSize/2, 0);
                    add(PASS, 3, 0);
                    add(PASS, 10, 2);
                    break;
                //Q8 Scenario: 4 Cars, PASS in middle to right of d1.
                case 111:
                    addDriver(0, 0, 1, "player", Direct.right);
                    addDriver(1, 2, 1, "driver2", Direct.right);
                    addDriver(3, RoadSize - 1, 1, "driver1", Direct.left);
                    addDriver(4, RoadSize - 3, 1, "driver3", Direct.left);
                    add(PASS, RoadSize/2, 2);
                    break;
                //EXTRA Scenario: 4 Cars, PASS in middle to right of d1 AND behind to the left of d1 AND behind to the left of d2.
                case 112:
                    addDriver(0, 0, 1, "player", Direct.right);
                    addDriver(1, 2, 1, "driver2", Direct.right);
                    addDriver(3, RoadSize - 1, 1, "driver1", Direct.left);
                    addDriver(4, RoadSize - 3, 1, "driver3", Direct.left);
                    add(PASS, RoadSize/2, 0);
                    add(PASS, 3, 0);
                    add(PASS, 10, 2);
                    break;
                case 201:
                    addDriver(0, 0, 1, "driverquestion1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverquestion2", Direct.left);
                    add(PASS, RoadSize/2, 0);
                    break;
                case 202:
                    addDriver(0, 0, 1, "driverquestion1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverquestion2", Direct.left);
                    add(PASS, 2, 0);
                    break;
                case 203:
                    addDriver(0, 0, 1, "driverquestion1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverquestion2", Direct.left);
                    add(PASS, 2, 2);
                    break;
                case 204:
                    addDriver(0, 0, 1, "driverquestion1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverquestion2", Direct.left);
                    add(PASS, 10, 2);
                    break;
                case 205:
                    addDriver(0, 0, 1, "driverquestion1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverquestion2", Direct.left);
                    add(PASS, 10, 0);
                    add(PASS, 2, 0);
                break;
                case 206:
                    addDriver(0, 0, 1, "driverquestion1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverquestion2", Direct.left);
                    break;
                case 207:
                    addDriver(0, 0, 1, "driverquestion1", Direct.right);
                    addDriver(1, RoadSize - 3, 1, "driverquestion2", Direct.left);
                    addDriver(2, RoadSize - 1, 1, "driverquestion3", Direct.left);
                    add(PASS, RoadSize/2, 0);
                    break;
                case 208:
                    addDriver(0, 0, 1, "driverquestion1", Direct.right);
                    addDriver(1, RoadSize - 3, 1, "driverquestion2", Direct.left);
                    addDriver(2, RoadSize - 1, 1, "driverquestion3", Direct.left);
                    add(PASS, RoadSize/2, 2);
                    break;
                case 209:
                    addDriver(0, 2, 1, "driverquestion1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverquestion2", Direct.left);
                    addDriver(2, 0, 1, "driverquestion3", Direct.right);
                    add(PASS, 2, 0);
                    break;
                case 210:
                    addDriver(0, 2, 1, "driverquestion1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverquestion2", Direct.left);
                    addDriver(2, 0, 1, "driverquestion3", Direct.right);
                    add(PASS, 5, 0);
                    add(PASS, 3, 0);
                    add(PASS, 9, 2);
                    break;
                case 211:
                    addDriver(0, 2, 1, "driverquestion1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverquestion2", Direct.left);
                    addDriver(2, 0, 1, "driverquestion3", Direct.right);
                    addDriver(3, RoadSize - 3, 1, "driverquestion4", Direct.left);
                    add(PASS, RoadSize/2, 2);
                    break;
                case 212:
                    addDriver(0, 2, 1, "driverquestion1", Direct.right);
                    addDriver(1, RoadSize - 3, 1, "driverquestion2", Direct.left);
                    addDriver(2, 0, 1, "driverquestion3", Direct.right);
                    addDriver(3, RoadSize - 1, 1, "driverquestion4", Direct.left);
                    add(PASS, RoadSize/2, 0);
                    add(PASS, 2, 0);
                    add(PASS, 10, 2);
                    break;
                case 213:
                    addDriver(0, 2, 1, "driverquestion1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverquestion2", Direct.left);
                    addDriver(2, 0, 1, "driverquestion3", Direct.right);
                    add(PASS, 2, 2);
                    break;
                case 301:
                    addDriver(0, 0, 1, "driverq_nocomm1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverq_nocomm2", Direct.left);
                    add(PASS, RoadSize/2, 0);
                    break;
                case 302:
                    addDriver(0, 0, 1, "driverq_nocomm1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverq_nocomm2", Direct.left);
                    add(PASS, 2, 0);
                    break;
                case 303:
                    addDriver(0, 0, 1, "driverq_nocomm1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverq_nocomm2", Direct.left);
                    add(PASS, 2, 2);
                    break;
                case 304:
                    addDriver(0, 0, 1, "driverq_nocomm1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverq_nocomm2", Direct.left);
                    add(PASS, 10, 0);
                    add(PASS, 2, 0);
                break;
                case 305:
                    addDriver(0, 0, 1, "driverq_nocomm1", Direct.right);
                    addDriver(1, RoadSize - 3, 1, "driverq_nocomm2", Direct.left);
                    addDriver(2, RoadSize - 1, 1, "driverq_nocomm3", Direct.left);
                    add(PASS, RoadSize/2, 0);
                    break;
                case 306:
                    addDriver(0, 0, 1, "driverq_nocomm1", Direct.right);
                    addDriver(1, RoadSize - 3, 1, "driverq_nocomm2", Direct.left);
                    addDriver(2, RoadSize - 1, 1, "driverq_nocomm3", Direct.left);
                    add(PASS, RoadSize/2, 2);
                    break;
                case 307:
                    addDriver(0, 2, 1, "driverq_nocomm1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverq_nocomm2", Direct.left);
                    addDriver(2, 0, 1, "driverq_nocomm3", Direct.right);
                    add(PASS, 2, 0);
                    break;
                case 308:
                    addDriver(0, 2, 1, "driverq_nocomm1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverq_nocomm2", Direct.left);
                    addDriver(2, 0, 1, "driverq_nocomm3", Direct.right);
                    add(PASS, 5, 0);
                    add(PASS, 3, 0);
                    add(PASS, 9, 2);
                    break;
                case 309:
                    addDriver(0, 2, 1, "driverq_nocomm1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverq_nocomm2", Direct.left);
                    addDriver(2, 0, 1, "driverq_nocomm3", Direct.right);
                    addDriver(3, RoadSize - 3, 1, "driverq_nocomm4", Direct.left);
                    add(PASS, RoadSize/2, 2);
                    break;
                case 310:
                    addDriver(0, 2, 1, "driverq_nocomm1", Direct.right);
                    addDriver(1, RoadSize - 3, 1, "driverq_nocomm2", Direct.left);
                    addDriver(2, 0, 1, "driverq_nocomm3", Direct.right);
                    addDriver(3, RoadSize - 1, 1, "driverq_nocomm4", Direct.left);
                    add(PASS, RoadSize/2, 0);
                    add(PASS, 2, 0);
                    add(PASS, 10, 2);
                    break;
                case 401:
                    addDriver(0, 0, 1, "driverq_comm1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverq_comm2", Direct.left);
                    add(PASS, RoadSize/2, 0);
                    break;
                case 402:
                    addDriver(0, 0, 1, "driverq_comm1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverq_comm2", Direct.left);
                    add(PASS, 2, 0);
                    break;
                case 403:
                    addDriver(0, 0, 1, "driverq_comm1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverq_comm2", Direct.left);
                    add(PASS, 2, 2);
                    break;
                case 404:
                    addDriver(0, 0, 1, "driverq_comm1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverq_comm2", Direct.left);
                    add(PASS, 10, 0);
                    add(PASS, 2, 0);
                    break;
                case 405:
                    addDriver(0, 0, 1, "driverq_comm1", Direct.right);
                    addDriver(1, RoadSize - 3, 1, "driverq_comm2", Direct.left);
                    addDriver(2, RoadSize - 1, 1, "driverq_comm3", Direct.left);
                    add(PASS, RoadSize/2, 0);
                    break;
                case 406:
                    addDriver(0, 0, 1, "driverq_comm1", Direct.right);
                    addDriver(1, RoadSize - 3, 1, "driverq_comm2", Direct.left);
                    addDriver(2, RoadSize - 1, 1, "driverq_comm3", Direct.left);
                    add(PASS, RoadSize/2, 2);
                    break;
                case 407:
                    addDriver(0, 2, 1, "driverq_comm1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverq_comm2", Direct.left);
                    addDriver(2, 0, 1, "driverq_comm3", Direct.right);
                    add(PASS, 2, 0);
                    break;
                case 408:
                    addDriver(0, 2, 1, "driverq_comm1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverq_comm2", Direct.left);
                    addDriver(2, 0, 1, "driverq_comm3", Direct.right);
                    add(PASS, 5, 0);
                    add(PASS, 3, 0);
                    add(PASS, 9, 2);
                    break;
                case 409:
                    addDriver(0, 2, 1, "driverq_comm1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverq_comm2", Direct.left);
                    addDriver(2, 0, 1, "driverq_comm3", Direct.right);
                    addDriver(3, RoadSize - 3, 1, "driverq_comm4", Direct.left);
                    add(PASS, RoadSize/2, 2);
                    break;
                case 410:
                    addDriver(0, 2, 1, "driverq_comm1", Direct.right);
                    addDriver(1, RoadSize - 3, 1, "driverq_comm2", Direct.left);
                    addDriver(2, 0, 1, "driverq_comm3", Direct.right);
                    addDriver(3, RoadSize - 1, 1, "driverq_comm4", Direct.left);
                    add(PASS, RoadSize/2, 0);
                    add(PASS, 2, 0);
                    add(PASS, 10, 2);
                    break;
                case 501:
                    addDriver(0, 0, 1, "driverq_hol1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverq_hol2", Direct.left);
                    add(PASS, RoadSize/2, 0);
                    break;
                case 502:
                    addDriver(0, 0, 1, "driverq_hol1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverq_hol2", Direct.left);
                    add(PASS, 2, 0);
                    break;
                case 503:
                    addDriver(0, 0, 1, "driverq_hol1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverq_hol2", Direct.left);
                    add(PASS, 2, 2);
                    break;
                case 504:
                    addDriver(0, 0, 1, "driverq_hol1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverq_hol2", Direct.left);
                    add(PASS, 10, 0);
                    add(PASS, 2, 0);
                    break;
                case 505:
                    addDriver(0, 0, 1, "driverq_hol1", Direct.right);
                    addDriver(1, RoadSize - 3, 1, "driverq_hol2", Direct.left);
                    addDriver(2, RoadSize - 1, 1, "driverq_hol3", Direct.left);
                    add(PASS, RoadSize/2, 0);
                    break;
                case 506:
                    addDriver(0, 0, 1, "driverq_hol1", Direct.right);
                    addDriver(1, RoadSize - 3, 1, "driverq_hol2", Direct.left);
                    addDriver(2, RoadSize - 1, 1, "driverq_hol3", Direct.left);
                    add(PASS, RoadSize/2, 2);
                    break;
                case 507:
                    addDriver(0, 2, 1, "driverq_hol1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverq_hol2", Direct.left);
                    addDriver(2, 0, 1, "driverq_hol3", Direct.right);
                    add(PASS, 2, 0);
                    break;
                case 508:
                    addDriver(0, 2, 1, "driverq_hol1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverq_hol2", Direct.left);
                    addDriver(2, 0, 1, "driverq_hol3", Direct.right);
                    add(PASS, 5, 0);
                    add(PASS, 3, 0);
                    add(PASS, 9, 2);
                    break;
                case 509:
                    addDriver(0, 2, 1, "driverq_hol1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverq_hol2", Direct.left);
                    addDriver(2, 0, 1, "driverq_hol3", Direct.right);
                    addDriver(3, RoadSize - 3, 1, "driverq_hol4", Direct.left);
                    add(PASS, RoadSize/2, 2);
                    break;
                case 510:
                    addDriver(0, 2, 1, "driverq_hol1", Direct.right);
                    addDriver(1, RoadSize - 3, 1, "driverq_hol2", Direct.left);
                    addDriver(2, 0, 1, "driverq_hol3", Direct.right);
                    addDriver(3, RoadSize - 1, 1, "driverq_hol4", Direct.left);
                    add(PASS, RoadSize/2, 0);
                    add(PASS, 2, 0);
                    add(PASS, 10, 2);
                    break;
                //Default: 2 cars, PASS in middle to left of d1.
                default: 
                    addDriver(0, 0, 1, "driver1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driver2", Direct.left);
                    add(PASS, RoadSize/2, 0);
                    break;
            }

            //Add road to the middle of row.
            for (int i = 0; i < RoadSize; i ++) {
                add(ROAD, i, 1);
            }
        }

        public void addDriver(int agID, int x, int y, String agName, Direct facing) {
            try {
                setAgPos(agID, x, y); //Agent id, x pos, y pos.
                
                //Add agent to both hashmaps.
                agentNameIdDict.put(agName, agID);
                agentNameIdInverse.put(agID, agName);

                //tell the agent which way it is facing.
                Literal dir = Literal.parseLiteral("facing(" + facing.toString() + ")");
                addPercept(agName, dir);

                //Adding the end-goal as percepts to the agent. This can be improved later as making the road end into a location variable that can be changed based on scenario.
                String roadEnd = "roadEnd(";
                if (facing == Direct.left) {
                    roadEnd = roadEnd + "0,1)";
                } else {
                    roadEnd = roadEnd + (RoadSize - 1) + ",1)";
                }
                addPercept(agName, Literal.parseLiteral(roadEnd));

            } catch (Exception e) {
                e.printStackTrace();
            }
        }

        public void moveForward(String agName, Direct facing) throws Exception {
            int agID = agentNameIdDict.get(agName);
            int coef = 1;
            if (facing == Direct.left) {
                coef = -1;
            }
    
            //Will worry about having up or down later)
            Location newPos = model.getAgPos(agID);
            newPos.x = newPos.x + coef;

            int otherAgID = model.getAgAtPos(newPos);
    
            if (otherAgID >= 0) {
                String roadBlockedText = "road_blocked(" + newPos.x + "," + newPos.y + ",occupied(" + agentNameIdInverse.get(otherAgID) + "))";
                addPercept(agName, Literal.parseLiteral(roadBlockedText));
                logger.info("AGENT CRASHED");
            } else {
                model.setAgPos(agID,newPos);
            }
            
            
            clearPercepts(agName);
            updatePercepts();
        }

        public void moveTo(String agName, Location newLoc) throws Exception {
            int agID = agentNameIdDict.get(agName);
    
            model.setAgPos(agID,newLoc);
            
            clearPercepts(agName);
            updatePercepts();
        }

        
    
        
    }

    //------GUI PART------
    class RoadView extends GridWorldView {

        public RoadView(RoadModel model) {
            super(model, "Straight STR", 500);
            defaultFont = new Font("Arial", Font.BOLD, 48); // change default font
            setVisible(true);
            repaint();
        }

        /** draw application objects */
        @Override
        public void draw(Graphics g, int x, int y, int object) {
            switch (object) {
            case Env.ROAD:
                drawRoad(g, x, y);
                break;
            case Env.PASS:
                drawPass(g, x, y);
                break;
            default:
                logger.info("Trying to draw non-existing object!");
                break;
            }
        }

        @Override
        public void drawAgent(Graphics g, int x, int y, Color c, int id) {
            String label = "D"+(id+1);
            c = Color.red;
            if (id == 0) {
                c = Color.blue;
            }

            super.drawAgent(g, x, y, c, -1);
            g.setColor(Color.white);
            super.drawString(g, x, y, defaultFont, label);
            repaint();
        }

        public void drawRoad(Graphics g, int x, int y) {
            g.setColor(Color.orange);
            g.fillRect(x * cellSizeW, y * cellSizeH, cellSizeW, cellSizeH);
        }

        public void drawPass(Graphics g, int x, int y) {
            g.setColor(Color.orange);
            g.fillRect(x * cellSizeW, y * cellSizeH, cellSizeW, cellSizeH);
            g.setColor(Color.black);
            drawString(g, x, y, defaultFont, "P");
        }



    }
}
