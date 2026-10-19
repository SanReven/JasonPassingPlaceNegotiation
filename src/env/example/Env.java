package example;

// Environment code for project simpleppapp

import jason.asSyntax.*;
import jason.bb.DefaultBeliefBase;
import jason.environment.*;
//import jason.asSyntax.parser.*;

import jason.environment.grid.GridWorldModel;
import jason.environment.grid.GridWorldView;
import jason.environment.grid.Location;
import jason.mas2j.ClassParameters;
import jason.runtime.Settings;
import jason.stdlib.print;

//import java.text.ParseException;
//import java.util.logging.*;

import java.awt.event.KeyEvent;
import java.awt.event.KeyListener;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Dictionary;

//import static java.lang.Math.abs;

import java.util.HashMap;
import java.util.List;
import jason.bb.DefaultBeliefBase;

//import javax.swing.JFrame;
//import javax.swing.JLabel;
//import javax.swing.border.EtchedBorder;

import java.awt.Color;
import java.awt.Font;
import java.awt.Graphics;
//import java.awt.Image;
import java.util.logging.Logger;
//import javax.swing.ImageIcon;



//import java.util.ArrayList;

import java.util.Random;


public class Env extends Environment {

    //-----AGENT PART------
    private Logger logger = Logger.getLogger("Jason Passing Place App."+Env.class.getName());

    private int worldOption;
    private int nbOfAgents;
    private RoadModel model;
    private RoadView view;

    private HashMap<String, Integer> agentNameIdDict = new HashMap<String, Integer>();
    private HashMap<Integer, String> agentNameIdInverse = new HashMap<Integer, String>();

    private HashMap<String, Env.Direct> agentDirDict = new HashMap<String, Env.Direct>();

    public static final int RoadSize = 13; // Road size
    public static final int ROAD = 16; //To determine where there is road.
    public static final int PASS = 32; //To determine where there is passing place.
    Random rand = new Random();

    public int pasID = 0; //number of passing places
    public int nbOfPasses = 0;

    public HashMap<String, Integer> agentStepCountDict = new HashMap<String, Integer>() {};

    public enum Direct {
        //Change to lowercase if agents are not happy storing full caps.
        up, right, left, down
    }


    

    /** Called before the MAS execution with the args informed in .mas2j */
    public void init(String[] args) {
        worldOption = Integer.parseInt(args[0]);
        nbOfAgents = Integer.parseInt(args[1]);

        //Handle the randomisation for the random scenario
        //Currently any world option number higher than 900 gets randomised. In future works this needs to be adapted if further numbers are introduced
        if (worldOption > 900) {
            //Code for handling custom seeds adapted from https://stackoverflow.com/questions/6001368/how-do-i-get-the-seed-from-a-random-in-java
            //To set a specific custom seed, comment out the line below
            int customSeed = rand.nextInt();
            //And uncomment the line below, inserting the specific seed.
            //long customSeed = ;
            rand.setSeed(customSeed);
            System.out.println("Running simulation with seed: " + customSeed);
            
            if(worldOption > 904) {
                nbOfPasses = nbOfAgents / 10;
                nbOfAgents = nbOfAgents % 10;
            } else {
                //rand.nextInt includes 0 but excludes the parameter given. We add +2 so the number of agents is between 2-4 
                nbOfAgents = rand.nextInt(3) + 2;
                //We restrict the number of passing places at 3, as any more would reduce the challenge of limited passing place availability.
                nbOfPasses = rand.nextInt(3) + 1;
                

                /*
            String tempAgName = "";

            if (worldOption == 901) {
                tempAgName = "driverhc";
            } else if (worldOption == 902) {
                tempAgName = "driverq_nocomm";
            } else if (worldOption == 903) {
                tempAgName = "driverq_comm";
            } else if (worldOption == 904) {
                tempAgName = "driverq_hon";
            } else {
                //Temporarily made into driverhc as a safeguard
                tempAgName = "driverhc";
            }


            
            OLD ATTEMPT AT SPAWNING AGENTS DYNAMICALLY, TAKEN FROM THE JASON FAQ. THIS DOES NOT WORK AT THE MOMENT.
            List<String> tempArchitectures = new ArrayList<>();


            //Assuming one agent is already in the simulation
            for (int i = 2; i < nbOfAgents + 1; i++) {
                String newAgName = tempAgName + i;
                try {
                    getEnvironmentInfraTier().getRuntimeServices().createAgent(
                        newAgName,     // agent name
                        tempAgName + ".asl",       // AgentSpeak source
                        "jason.asSemantics.Agent",            // default agent class
                        tempArchitectures,            // default architecture class
                        new ClassParameters("jason.bb.JDBCPersistentBB"),            // default belief base parameters
                        new Settings(), // default settings
                        getEnvironmentInfraTier().getRuntimeServices().getAgentSnapshot("hcdriver1"));
                        //Start the spawned agent
                        getEnvironmentInfraTier().getRuntimeServices().startAgent(newAgName);   
                } catch (Exception e) {
                    // Handle the failure (e.g., if the .asl file isn't found or class loading fails)
                    System.err.println("Failed to dynamically spawn the agent: " + e.getMessage());
                    e.printStackTrace(); 
                }
            }
                */
            }

            
        };
        

        model = new RoadModel(worldOption, nbOfAgents);
        view  = new RoadView(model);
        model.setView(view);
        updatePercepts();
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
                System.out.println(agName + " FINISHED WITH STEPS: " + agentStepCountDict.get(agName));
            } else {
                return false;
            }

            //if (agentStepCountDict.get(agName) != null) {
            //    agentStepCountDict.put(agName, agentStepCountDict.get(agName) + 1);
            //} else {
            //    agentStepCountDict.put(agName, 1);
            //}
            System.out.println(agName + " steps taken: " + agentStepCountDict.get(agName));
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
    void updatePercepts() {
        for (String agName : agentNameIdDict.keySet()) {
            int agID = agentNameIdDict.get(agName);


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

    //Method for agents to check the spaces ahead of themselves based on which they are facing and how far ahead they are looking. Uses checkLocation for detailed information.
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

    //Method for agents to check the spaces behind themselves. Similar to check ahead, but mirrored, with respect to which way left and right is for the agent.
    public void checkBehind(String agName, int viewDist, Direct facing) throws Exception {
        Location agLoc = model.getAgPos(agentNameIdDict.get(agName));
        
        clearPercepts(agName);
        int coef = 1;

        if (facing == Direct.right) {
            coef = -1;
        }

        for (int i = 1; i < viewDist + 1; i++) {
            checkLocation(agLoc.x + (coef * i), agLoc.y, agName, (coef * (-1)));
            checkLocation(agLoc.x + (coef * i), agLoc.y + 1, agName, (coef * (-1)));
            checkLocation(agLoc.x + (coef * i), agLoc.y - 1, agName, (coef * (-1)));
        }
    }

    //Compiles and returns detailed information on the currently viewed space.
    //Information includes: Coordinates of space, whether there is any road, whether the road is occupied and by who, and if there are any passing places adjecent to the road.
    public void checkLocation(int x, int y, String agName, int directionCoef) throws Exception {

        boolean agentFound = false;

        String tempPercept = "";

        String pass;
        String occupied;

        pass = "none";
        occupied = "free";

        int otherAg = model.getAgAtPos(x, y);

        //If there is an agent there:
        if (otherAg >= 0) {
            //There seems to be no known way on how to get an agent object from string/id alone. Implemented a hashmap solution in its place instead.
            String otherName = agentNameIdInverse.get(otherAg);
            String facing = agentDirDict.get(otherName).toString();
            Literal driverDet = Literal.parseLiteral("driver_detected(" + otherName + "," + facing + ")");
            addPercept(agName, driverDet);
            occupied = "occupied(" + otherName + ")";
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
        } else if (model.hasObject(PASS, x, y)) {
            //If facing left, a pass on the left should be (2 + (- 1)). If facing right, a pass on the left should be (0 + 1).
            if ((y + directionCoef) == 1) {
                pass = "left";
            } else {
                pass = "right";
            }

            Literal road = Literal.parseLiteral("pass(" + x + "," + y + "," + occupied + "," + pass + ")");
            addPercept(agName, road);
        } else {
            ;
            //No percept addition is needed here as of now.
        }
    }

    
    //Method to pull out of a passing place, placing the agent one step forward and onto the road.
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

            //Random passing place layout setup. This will not be used in scenarios outside of 901-908.
            List<Integer> passPosList = new ArrayList<>();

            //Randomising a list of numbers without repeats adapted from https://www.baeldung.com/java-unique-random-numbers
            for(int i = 0; i < nbOfPasses; i++) {
                //The positions of passing places are between the starting positions of agent 3 and agent 4
                passPosList.add(rand.nextInt(RoadSize - 4) + 2);
            }
            Collections.shuffle(passPosList, rand);

            // initial location of agents and Passing places based on world type

            switch(worldType) {
                //HIGHWAY CODE AGENTS
                //S1: 2 Cars, PASS in middle to left of d1. Simple common scenario where two drivers meet around a passing place.
                //(Q4 in questionnaire based on this)
                case 1:
                    addDriver(0, 0, 1, "driverhc1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverhc2", Direct.left);
                    add(PASS, RoadSize/2, 0);
                    break;
                //S2: 2 Cars, PASS behind to left of d1. Also simple common scenario where two drivers meet but not near a passing place. As in the Highway Code, someone has to reverse.
                //(Q6 based on this)
                case 2:
                    addDriver(0, 0, 1, "driverhc1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverhc2", Direct.left);
                    add(PASS, 2, 0);
                    break;
                //S3: 2 Cars, PASS behind to right of d1. Additional scenario based on S2, exploring how would the resolution change if the passing place is on the opposite side of the driver reversing.
                //(Q5 based on this)
                case 3:
                    addDriver(0, 0, 1, "driverhc1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverhc2", Direct.left);
                    add(PASS, 2, 2);
                    break;
                //S4: 2 Cars, PASS behind to left of d1 AND PASS behind to the right of d2. Additional scenario, exploring how agents would resolve the scenario if both agents were equal distance from the passing place.
                case 4:
                    addDriver(0, 0, 1, "driverhc1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverhc2", Direct.left);
                    add(PASS, 10, 0);
                    add(PASS, 2, 0);
                    break;
                //S5: 3 Cars, PASS in middle to left of d1, extra car behind d2. Expanding on S1, but now there are 3 agents present.
                case 5:
                    addDriver(0, 0, 1, "driverhc1", Direct.right);
                    addDriver(1, RoadSize - 3, 1, "driverhc2", Direct.left);
                    addDriver(2, RoadSize - 1, 1, "driverhc3", Direct.left);
                    add(PASS, RoadSize/2, 0);
                    break;
                //S6: 3 Cars, PASS in middle to right of d1, extra car behind d2. Modification of S5, exploring how the resolution would differ if the passing place was opposite the lone driver.
                //(Q7 based on this)
                case 6:
                    addDriver(0, 0, 1, "driverhc1", Direct.right);
                    addDriver(1, RoadSize - 3, 1, "driverhc2", Direct.left);
                    addDriver(2, RoadSize - 1, 1, "driverhc3", Direct.left);
                    add(PASS, RoadSize/2, 2);
                    break;
                //S7: 3 Cars, PASS behind to left of d1, extra car behind d1. Exploring how two agents can manage reversing together to a passing place and manage the scenario around it.
                //As stated in online guides, there is a risk of more drivers approaching from behind when reversing, and drivers need to be cautious while reversing as such.
                //(Q9 based on this)
                case 7:
                    addDriver(0, 2, 1, "driverhc1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverhc2", Direct.left);
                    addDriver(2, 0, 1, "driverhc3", Direct.right);
                    add(PASS, 2, 0);
                    break;
                //S8: 3 cars, PASS in middle to the left of d1 AND behind to the left of d1 AND behind to the left of d2, extra car behind d1. Expanded S7, exploring if the resolution changes with more passing places.
                case 8:
                    addDriver(0, 2, 1, "driverhc1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverhc2", Direct.left);
                    addDriver(2, 0, 1, "driverhc3", Direct.right);
                    add(PASS, 5, 0);
                    add(PASS, 3, 0);
                    add(PASS, 9, 2);
                    break;
                //S9: 4 Cars, PASS in middle to right of d1. Expansion of S1/S5, now with 4 agents around 1 passing place.
                //(Q8 based on this)
                case 9:
                    addDriver(0, 2, 1, "driverhc1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverhc2", Direct.left);
                    addDriver(2, 0, 1, "driverhc3", Direct.right);
                    addDriver(3, RoadSize - 3, 1, "driverhc4", Direct.left);
                    add(PASS, RoadSize/2, 2);
                    break;
                //S10: 4 Cars, PASS in middle to right of d1 AND behind to the left of d1 AND behind to the left of d3. Expansion of S9, now with 3 passing places, exploring how more passing places can alter the resolution if at all.
                case 10:
                    addDriver(0, 2, 1, "driverhc1", Direct.right);
                    addDriver(1, RoadSize - 3, 1, "driverhc2", Direct.left);
                    addDriver(2, 0, 1, "driverhc3", Direct.right);
                    addDriver(3, RoadSize - 1, 1, "driverhc4", Direct.left);
                    add(PASS, RoadSize/2, 0);
                    add(PASS, 2, 0);
                    add(PASS, 10, 2);
                    break;

                //QUESTIONNAIRE AGENTS
                //Questionnaire - No communication agents
                //S1: 2 Cars, PASS in middle to left of d1.
                case 101:
                    addDriver(0, 0, 1, "driverq_nocomm1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverq_nocomm2", Direct.left);
                    add(PASS, RoadSize/2, 0);
                    break;
                //S2: 2 Cars, PASS behind to left of d1.
                case 102:
                    addDriver(0, 0, 1, "driverq_nocomm1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverq_nocomm2", Direct.left);
                    add(PASS, 2, 0);
                    break;
                //S3: 2 Cars, PASS behind to right of d1.
                case 103:
                    addDriver(0, 0, 1, "driverq_nocomm1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverq_nocomm2", Direct.left);
                    add(PASS, 2, 2);
                    break;
                //S4: 2 Cars, PASS behind to left of d1 AND PASS behind to the right of d2.
                case 104:
                    addDriver(0, 0, 1, "driverq_nocomm1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverq_nocomm2", Direct.left);
                    add(PASS, 10, 0);
                    add(PASS, 2, 0);
                break;
                //S5: 3 Cars, PASS in middle to left of d1, extra car behind d2.
                case 105:
                    addDriver(0, 0, 1, "driverq_nocomm1", Direct.right);
                    addDriver(1, RoadSize - 3, 1, "driverq_nocomm2", Direct.left);
                    addDriver(2, RoadSize - 1, 1, "driverq_nocomm3", Direct.left);
                    add(PASS, RoadSize/2, 0);
                    break;
                //S6: 3 Cars, PASS in middle to right of d1, extra car behind d2.
                case 106:
                    addDriver(0, 0, 1, "driverq_nocomm1", Direct.right);
                    addDriver(1, RoadSize - 3, 1, "driverq_nocomm2", Direct.left);
                    addDriver(2, RoadSize - 1, 1, "driverq_nocomm3", Direct.left);
                    add(PASS, RoadSize/2, 2);
                    break;
                //S7: 3 Cars, PASS behind to left of d1, extra car behind d1.
                case 107:
                    addDriver(0, 2, 1, "driverq_nocomm1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverq_nocomm2", Direct.left);
                    addDriver(2, 0, 1, "driverq_nocomm3", Direct.right);
                    add(PASS, 2, 0);
                    break;
                //S8: 3 cars, PASS in middle to the left of d1 AND behind to the left of d1 AND behind to the left of d2, extra car behind d1.
                case 108:
                    addDriver(0, 2, 1, "driverq_nocomm1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverq_nocomm2", Direct.left);
                    addDriver(2, 0, 1, "driverq_nocomm3", Direct.right);
                    add(PASS, 5, 0);
                    add(PASS, 3, 0);
                    add(PASS, 9, 2);
                    break;
                //S9: 4 Cars, PASS in middle to right of d1.
                case 109:
                    addDriver(0, 2, 1, "driverq_nocomm1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverq_nocomm2", Direct.left);
                    addDriver(2, 0, 1, "driverq_nocomm3", Direct.right);
                    addDriver(3, RoadSize - 3, 1, "driverq_nocomm4", Direct.left);
                    add(PASS, RoadSize/2, 2);
                    break;
                //S10: 4 Cars, PASS in middle to right of d1 AND behind to the left of d1 AND behind to the left of d3.
                case 110:
                    addDriver(0, 2, 1, "driverq_nocomm1", Direct.right);
                    addDriver(1, RoadSize - 3, 1, "driverq_nocomm2", Direct.left);
                    addDriver(2, 0, 1, "driverq_nocomm3", Direct.right);
                    addDriver(3, RoadSize - 1, 1, "driverq_nocomm4", Direct.left);
                    add(PASS, RoadSize/2, 0);
                    add(PASS, 2, 0);
                    add(PASS, 10, 2);
                    break;

                //Questionnaire - Communicative Agents
                //S1: 2 Cars, PASS in middle to left of d1.
                case 201:
                    addDriver(0, 0, 1, "driverq_comm1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverq_comm2", Direct.left);
                    add(PASS, RoadSize/2, 0);
                    break;
                //S2: 2 Cars, PASS behind to left of d1.
                case 202:
                    addDriver(0, 0, 1, "driverq_comm1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverq_comm2", Direct.left);
                    add(PASS, 2, 0);
                    break;
                //S3: 2 Cars, PASS behind to right of d1.
                case 203:
                    addDriver(0, 0, 1, "driverq_comm1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverq_comm2", Direct.left);
                    add(PASS, 2, 2);
                    break;
                //S4: 2 Cars, PASS behind to left of d1 AND PASS behind to the right of d2.
                case 204:
                    addDriver(0, 0, 1, "driverq_comm1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverq_comm2", Direct.left);
                    add(PASS, 10, 0);
                    add(PASS, 2, 0);
                    break;
                //S5: 3 Cars, PASS in middle to left of d1, extra car behind d2.
                case 205:
                    addDriver(0, 0, 1, "driverq_comm1", Direct.right);
                    addDriver(1, RoadSize - 3, 1, "driverq_comm2", Direct.left);
                    addDriver(2, RoadSize - 1, 1, "driverq_comm3", Direct.left);
                    add(PASS, RoadSize/2, 0);
                    break;
                //S6: 3 Cars, PASS in middle to right of d1, extra car behind d2.
                case 206:
                    addDriver(0, 0, 1, "driverq_comm1", Direct.right);
                    addDriver(1, RoadSize - 3, 1, "driverq_comm2", Direct.left);
                    addDriver(2, RoadSize - 1, 1, "driverq_comm3", Direct.left);
                    add(PASS, RoadSize/2, 2);
                    break;
                //S7: 3 Cars, PASS behind to left of d1, extra car behind d1.
                case 207:
                    addDriver(0, 2, 1, "driverq_comm1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverq_comm2", Direct.left);
                    addDriver(2, 0, 1, "driverq_comm3", Direct.right);
                    add(PASS, 2, 0);
                    break;
                //S8: 3 cars, PASS in middle to the left of d1 AND behind to the left of d1 AND behind to the left of d2, extra car behind d1.
                case 208:
                    addDriver(0, 2, 1, "driverq_comm1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverq_comm2", Direct.left);
                    addDriver(2, 0, 1, "driverq_comm3", Direct.right);
                    add(PASS, 5, 0);
                    add(PASS, 3, 0);
                    add(PASS, 9, 2);
                    break;
                //S9: 4 Cars, PASS in middle to right of d1.
                case 209:
                    addDriver(0, 2, 1, "driverq_comm1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverq_comm2", Direct.left);
                    addDriver(2, 0, 1, "driverq_comm3", Direct.right);
                    addDriver(3, RoadSize - 3, 1, "driverq_comm4", Direct.left);
                    add(PASS, RoadSize/2, 2);
                    break;
                //S10: 4 Cars, PASS in middle to right of d1 AND behind to the left of d1 AND behind to the left of d3.
                case 210:
                    addDriver(0, 2, 1, "driverq_comm1", Direct.right);
                    addDriver(1, RoadSize - 3, 1, "driverq_comm2", Direct.left);
                    addDriver(2, 0, 1, "driverq_comm3", Direct.right);
                    addDriver(3, RoadSize - 1, 1, "driverq_comm4", Direct.left);
                    add(PASS, RoadSize/2, 0);
                    add(PASS, 2, 0);
                    add(PASS, 10, 2);
                    break;
                
                //Questionnaire - Higher Order Negotiation Agents
                //S1: 2 Cars, PASS in middle to left of d1.
                case 301:
                    addDriver(0, 0, 1, "driverq_hon1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverq_hon2", Direct.left);
                    add(PASS, RoadSize/2, 0);
                    break;
                //S2: 2 Cars, PASS behind to left of d1.
                case 302:
                    addDriver(0, 0, 1, "driverq_hon1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverq_hon2", Direct.left);
                    add(PASS, 2, 0);
                    break;
                //S3: 2 Cars, PASS behind to right of d1.
                case 303:
                    addDriver(0, 0, 1, "driverq_hon1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverq_hon2", Direct.left);
                    add(PASS, 2, 2);
                    break;
                //S4: 2 Cars, PASS behind to left of d1 AND PASS behind to the right of d2.
                case 304:
                    addDriver(0, 0, 1, "driverq_hon1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverq_hon2", Direct.left);
                    add(PASS, 10, 0);
                    add(PASS, 2, 0);
                    break;
                //S5: 3 Cars, PASS in middle to left of d1, extra car behind d2.
                case 305:
                    addDriver(0, 0, 1, "driverq_hon1", Direct.right);
                    addDriver(1, RoadSize - 3, 1, "driverq_hon2", Direct.left);
                    addDriver(2, RoadSize - 1, 1, "driverq_hon3", Direct.left);
                    add(PASS, RoadSize/2, 0);
                    break;
                //S6: 3 Cars, PASS in middle to right of d1, extra car behind d2.
                case 306:
                    addDriver(0, 0, 1, "driverq_hon1", Direct.right);
                    addDriver(1, RoadSize - 3, 1, "driverq_hon2", Direct.left);
                    addDriver(2, RoadSize - 1, 1, "driverq_hon3", Direct.left);
                    add(PASS, RoadSize/2, 2);
                    break;
                //S7: 3 Cars, PASS behind to left of d1, extra car behind d1.
                case 307:
                    addDriver(0, 2, 1, "driverq_hon1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverq_hon2", Direct.left);
                    addDriver(2, 0, 1, "driverq_hon3", Direct.right);
                    add(PASS, 2, 0);
                    break;
                //S8: 3 cars, PASS in middle to the left of d1 AND behind to the left of d1 AND behind to the left of d2, extra car behind d1.
                case 308:
                    addDriver(0, 2, 1, "driverq_hon1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverq_hon2", Direct.left);
                    addDriver(2, 0, 1, "driverq_hon3", Direct.right);
                    add(PASS, 5, 0);
                    add(PASS, 3, 0);
                    add(PASS, 9, 2);
                    break;
                //S9: 4 Cars, PASS in middle to right of d1.
                case 309:
                    addDriver(0, 2, 1, "driverq_hon1", Direct.right);
                    addDriver(1, RoadSize - 3, 1, "driverq_hon2", Direct.left);
                    addDriver(2, 0, 1, "driverq_hon3", Direct.right);
                    addDriver(3, RoadSize - 1, 1, "driverq_hon4", Direct.left);
                    add(PASS, RoadSize/2, 2);
                    break;
                //S10: 4 Cars, PASS in middle to right of d1 AND behind to the left of d1 AND behind to the left of d3.
                case 310:
                    addDriver(0, 2, 1, "driverq_hon1", Direct.right);
                    addDriver(1, RoadSize - 3, 1, "driverq_hon2", Direct.left);
                    addDriver(2, 0, 1, "driverq_hon3", Direct.right);
                    addDriver(3, RoadSize - 1, 1, "driverq_hon4", Direct.left);
                    add(PASS, RoadSize/2, 0);
                    add(PASS, 2, 0);
                    add(PASS, 10, 2);
                    break;

                //RANDOMISED SCENARIOS
                //Highway Code Agents
                case 901:
                    addDriver(0, 0, 1, "driverhc1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverhc2", Direct.left);
                    if (agNumber > 2) {
                        addDriver(2, 2, 1, "driverhc3", Direct.right);
                    }
                    if (agNumber > 3) {
                        addDriver(3, RoadSize - 3, 1, "driverhc4", Direct.left);
                    }

                    for(int i = 0; i < nbOfPasses; i++)
                        //Random number of 1 or -1 without 0 adapted from https://stackoverflow.com/questions/6347995/java-generate-a-random-1-or-1
                        add(PASS, passPosList.remove(0), (rand.nextBoolean() ? 1 : -1) + 1);
                    break;
                case 902:
                    addDriver(0, 0, 1, "driverq_nocomm1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverq_nocomm2", Direct.left);
                    if (agNumber > 2) {
                        addDriver(2, 2, 1, "driverq_nocomm3", Direct.right);
                    }
                    if (agNumber > 3) {
                        addDriver(3, RoadSize - 3, 1, "driverq_nocomm4", Direct.left);
                    }

                    for(int i = 0; i < nbOfPasses; i++)
                        add(PASS, passPosList.remove(0), (rand.nextBoolean() ? 1 : -1) + 1);
                    break;
                case 903:
                    addDriver(0, 0, 1, "driverq_comm1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverq_comm2", Direct.left);
                    if (agNumber > 2) {
                        addDriver(2, 2, 1, "driverq_comm3", Direct.right);
                    }
                    if (agNumber > 3) {
                        addDriver(3, RoadSize - 3, 1, "driverq_comm4", Direct.left);
                    }

                    for(int i = 0; i < nbOfPasses; i++)
                        add(PASS, passPosList.remove(0), (rand.nextBoolean() ? 1 : -1) + 1);
                    break;
                case 904:
                    addDriver(0, 0, 1, "driverq_hon1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverq_hon2", Direct.left);
                    if (agNumber > 2) {
                        addDriver(2, 2, 1, "driverq_hon3", Direct.right);
                    }
                    if (agNumber > 3) {
                        addDriver(3, RoadSize - 3, 1, "driverq_hon4", Direct.left);
                    }

                    for(int i = 0; i < nbOfPasses; i++)
                        add(PASS, passPosList.remove(0), (rand.nextBoolean() ? 1 : -1) + 1);
                    break;
                case 905:
                    addDriver(0, 0, 1, "driverhc1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverhc2", Direct.left);
                    if (agNumber > 2) {
                        addDriver(2, 2, 1, "driverhc3", Direct.right);
                    }
                    if (agNumber > 3) {
                        addDriver(3, RoadSize - 3, 1, "driverhc4", Direct.left);
                    }
                    if (agNumber > 4) {
                        addDriver(4, 4, 1, "driverhc5", Direct.right);
                    }
                    if (agNumber > 5) {
                        addDriver(5, RoadSize - 5, 1, "driverhc6", Direct.left);
                    }
                    
                    for(int i = 0; i < nbOfPasses; i++)
                        add(PASS, passPosList.remove(0), (rand.nextBoolean() ? 1 : -1) + 1);
                    break;
                case 906:
                    addDriver(0, 0, 1, "driverq_nocomm1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverq_nocomm2", Direct.left);
                    if (agNumber > 2) {
                        addDriver(2, 2, 1, "driverq_nocomm3", Direct.right);
                    }
                    if (agNumber > 3) {
                        addDriver(3, RoadSize - 3, 1, "driverq_nocomm4", Direct.left);
                    }
                    if (agNumber > 4) {
                        addDriver(4, 4, 1, "driverq_nocomm5", Direct.right);
                    }
                    if (agNumber > 5) {
                        addDriver(5, RoadSize - 5, 1, "driverq_nocomm6", Direct.left);
                    }
                    
                    for(int i = 0; i < nbOfPasses; i++)
                        add(PASS, passPosList.remove(0), (rand.nextBoolean() ? 1 : -1) + 1);
                    break;
                case 907:
                    addDriver(0, 0, 1, "driverq_comm1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverq_comm2", Direct.left);
                    if (agNumber > 2) {
                        addDriver(2, 2, 1, "driverq_comm3", Direct.right);
                    }
                    if (agNumber > 3) {
                        addDriver(3, RoadSize - 3, 1, "driverq_comm4", Direct.left);
                    }
                    if (agNumber > 4) {
                        addDriver(4, 4, 1, "driverq_comm5", Direct.right);
                    }
                    if (agNumber > 5) {
                        addDriver(5, RoadSize - 5, 1, "driverq_comm6", Direct.left);
                    }
                    
                    for(int i = 0; i < nbOfPasses; i++)
                        add(PASS, passPosList.remove(0), (rand.nextBoolean() ? 1 : -1) + 1);
                    break;
                case 908:
                    addDriver(0, 0, 1, "driverq_hon1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverq_hon2", Direct.left);
                    if (agNumber > 2) {
                        addDriver(2, 2, 1, "driverq_hon3", Direct.right);
                    }
                    if (agNumber > 3) {
                        addDriver(3, RoadSize - 3, 1, "driverq_hon4", Direct.left);
                    }
                    if (agNumber > 4) {
                        addDriver(4, 4, 1, "driverq_hon5", Direct.right);
                    }
                    if (agNumber > 5) {
                        addDriver(5, RoadSize - 5, 1, "driverq_hon", Direct.left);
                    }

                    for(int i = 0; i < nbOfPasses; i++)
                        add(PASS, passPosList.remove(0), (rand.nextBoolean() ? 1 : -1) + 1);
                    break;
                

                //Default: 2 cars, PASS in middle to left of d1.
                default: 
                    addDriver(0, 0, 1, "driverhc1", Direct.right);
                    addDriver(1, RoadSize - 1, 1, "driverhc2", Direct.left);
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
                agentDirDict.put(agName, facing);

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

        //Method for agents to take a step forward
        public void moveForward(String agName, Direct facing) throws Exception {
            int agID = agentNameIdDict.get(agName);
            int coef = 1;
            if (facing == Direct.left) {
                coef = -1;
            }
    
            Location newPos = model.getAgPos(agID);
            newPos.x = newPos.x + coef;

            int otherAgID = model.getAgAtPos(newPos);
    
            if (otherAgID >= 0) {
                String roadBlockedText = "road_blocked(" + newPos.x + "," + newPos.y + ",occupied(" + agentNameIdInverse.get(otherAgID) + "))";
                addPercept(agName, Literal.parseLiteral(roadBlockedText));
                logger.info("AGENT CRASHED: " + agName);
            } else {
                model.setAgPos(agID,newPos);
            }
            
            
            clearPercepts(agName);
            updatePercepts();
        }

        //Basic function to move agents to a specified space.
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
            Direct agentDir = agentDirDict.get(agentNameIdInverse.get(id));
            if (agentDir == Direct.right) {
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
