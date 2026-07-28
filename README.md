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


