# Jason Passing Place Negotiation
The Jason project built for exploring the Passing Place Problem using AgentSpeak agents.

The project features four agents in 10 scenarios:
-Highway Code Agent (HC Agent) - This is noted as "driverhc"
-Questionnaire Base Agent (QB Agent) - This is noted as "driverq_nocomm"
-Questionnaire Communicative Agent (QC Agent) - This is noted as "driverq_comm"
-Questionnaire Higher Order Negotiation Agent (QH Agent) - This is noted as "driverq_hon"

To run the project:
-Load the project in your IDE of choice (I use VSCode)
-Open main.mas2j
-Edit the X and Y values in "environment: example.Env(X,Y)", where X refers to the scenario number, and Y refers to the number of agents in the scene.
    -A guide for each scenario is provided in the file.
-Uncomment the agent type corresponding to the scenario (Comment out all other agent types), and type the number of agents in the scene after the "#". (The same as Y value from before).
    -For example, to start scenario 9 with the QH Agent:
        -Edit the environment parameters to "environment: example.Env(309,4)"
        -Comment out all agent types below (Add // to before each agent type, if they do not have it already)
        -Uncomment "driverq_hon #X" (Remove the //). Change X to 4.
        -Open the terminal within the IDE
        -Type "./gradlew run"

This project can be opened in your IDE of choice and ran using the terminal, as Jason is bundled together with this project.
If the project is not running, download Jason from the website https://jason-lang.github.io before attempting to run again.
The project was built using Jason 3.3.0. Behaviours are not expected to change with future versions, but it nay not be impossible to observe different behaviours as the framework gets updated.

A set of randomised scenarios have been introduced as part of additional development. These scenarios (901-904) offer randomised number of agents and randomised number of passing places in random positions. A random seed is provided in the console at the beginning of every randomised run, which can be saved and input into the code for later repeated runs of the same layout. The maximum number of agents and passing places were kept to 4 and 3 respectively, similar to the highest numbers present in the 10 scenarios. Keeping the agents from becoming too numerous ensures that the scenario is not over-crowded. Keeping the number of passing places from becoming too numerous ensures the limitation of passing place availability remains relevant.

Note: On rare occasions, it was found that an agent's movement may be processed a step later than it should be. This causes one of two agents to travel one step further upon meeting. This does not cause the agents to crash, nor does it change the outcome of the scenario, but it may cause some visual inconsistency compared to the results presented in the thesis. The system is deterministic and this shift only happens on rare occasions, but if the user is uncertain, multiple runs should be done to ensure the results are correct.


