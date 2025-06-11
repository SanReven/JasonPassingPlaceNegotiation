// Agent driverquestion
//This agent negotiates passing places according to the Questionnaire results and questionnaire decision tree.

/* Initial beliefs and rules */
vision_dist(3).
//This is to differentiate between initial facing dir and other agents' facing dir.


/* Initial goals */

!start.

/* Plans */
+!start : true <-   .wait(2000);
                    !drive.

+!start <- !start.


+facing(Dir)[source(A)] : not my_name(A) <- +facing(Dir).

+roadEnd(X,Y)[source(A)] : not my_name(A) <- +roadEnd(X,Y).

/*Convert passing place percept into belief*/
+last_pass(_,_,_,_)
    <-  -last_pass(_);
        .print("PASSING PLACE OBTAINED");
        +pass_found(0).


//Basic plans for driving, remembering passing places, negotiating passing places

+road_blocked(_)
    <-  .drop_all_desires;
        .print("I HAVE CRASHED!");
        !stop.

+!drive : pos(_, X,Y) & roadEnd(X,Y)
    <-  .my_name(A);
        .print("I have reached my destination. Goodbye!");
        //Temporary solution to get agents out of the way
        remove_me;
        .kill_agent(A).


//LOGIC FOR WHEN ENCOUNTERING ANOTHER VEHICLE.

//While driving and there is another driver ahead that I know is reversing.
//I will stop following the driver, and instead begin resolving. This will make me go to reverse immediately.
+!drive : road(_,_,occupied(Driver),_) & driver_ahead_reversing
    <-  -following(Driver);
        !resolve;
        !drive.

//While driving and there is another driver ahead that I am already following
//I will wait a second then continue driving. THIS IS HANDLED IN RESOLVE
/*+!drive : road(_,_,occupied(Driver),_) & following(Driver)
    <-  .wait(500);
        ?vision_dist(Vis);
        ?facing(Dir);
        check_ahead(Vis,Dir);
        !drive.*/ 


//When driving and encountering another driver ahead.
//I will begin resolving the scenario.
+!drive : road(_,_,occupied(Driver),_)
    <-  .wait(500);
        +resolving_with(Driver);
        ?vision_dist(Vis);
        ?facing(Dir);
        check_ahead(Vis,Dir);
        !resolve;
        .print("SUCCESSFULLY RESUMED DRIVING");
        !drive.


//While driving on a clear road and I know of a passing place behind, move forward and increase the distance it is away from me.
+!drive : road(_,_,free,_) & pass_found(Dist)
    <-  ?facing(Dir);
        move_forward(Dir);
        -pass_found(Dist);
        +pass_found(Dist + 1);
        .wait(500);
        !drive.

//While driving and I know the road is clear, take a step forward.
+!drive : road(_,_,free,_) 
    <-  ?facing(Dir);
        move_forward(Dir);
        .wait(500);
        !drive.

//While driving and I am not sure if the road is clear, check the road ahead.
+!drive : not road(_,_,_,_)
    <-  ?vision_dist(Vis);
        ?facing(Dir);
        check_ahead(Vis,Dir);
        !drive.

+!drive <- !drive.

//When leaving a passing place that I stopped opposite of.
//Note that passing place as a past passing place.
-opposite_pass
    <-  -resolving_with(_);
        ?pos(_,X,Y);
        //!!!!!!!Y value hard-coded for now. Would need to implement an if-statement and checking for where the road is later.
        -pass_found(_);
        +pass_found(0).

//When leaving a passing place that I pulled into.
//Note that passing place as a past passing place.
-in_pass(_)
    <-  -resolving_with(_);
        ?pos(_,X,Y);
        //!!!!!!!Y value hard-coded for now. Would need to implement an if-statement and checking for where the road is later.
        -pass_found(_);
        +pass_found(0).


//RESOLVE ACTIONS



+!resolve : wait_for(0) & road(_,_,occupied(Driver),_)
    <-  .print("No longer waiting. Starting to reverse");
        -wait_for(0);
        ?facing(Dir);
        check_behind(1, Dir);
        !reverse;
        !resolve.


+!resolve : wait_for(X) & road(_,_,occupied(Driver),_)
    <-  .print("Still waiting...");
        .print(X);
        -wait_for(X);
        +wait_for(X - 1);
        .wait(500);
        ?vision_dist(Vis);
        ?facing(Dir);
        check_ahead(Vis,Dir);
        !resolve.

+!resolve : wait_for(X)
    <-  .print("Other driver began moving. I will follow");
        -wait_for(X).


//If the driver ahead is reversing, go straight to reversing as well
+!resolve : resolving_with(Driver) & following(Driver)
    <-  .print("Driver ahead of me stopped. I will wait to see if they move again");
        +wait_for(5);
        ?vision_dist(Vis);
        ?facing(Dir);
        check_ahead(Vis,Dir);
        !resolve.


//Driver found behind.
//The agent goes into wait_for_others mode and waits until someone moves out of the way.
+!resolve : checking_driver_behind & road(_,_,occupied(Behind),_)
    <-  -checking_driver_behind;
        .print("There is a driver in front and a driver behind. I will begin waiting for them.");
        .wait(500);
        ?facing(Dir);
        ?vision_dist(Vis);
        check_ahead(Vis,Dir);
        !wait_for_others;
        !resolve.

//No driver found behind. Begin reversing
//Agent will begin reversing.
+!resolve : checking_driver_behind & road(_,_,free,_)
    <-  -checking_driver_behind;
        .print("No driver found behind. Waiting to see if driver in front reverses first.");
        ?pass_found(X);
        +wait_for(X);
        ?vision_dist(Vis);
        ?facing(Dir);
        check_ahead(Vis,Dir);
        !resolve.


+!resolve : checking_driver_behind
    <-  ?facing(Dir);
        ?vision_dist(Vis);
        check_behind(Vis,Dir).



//REMAINING RESOLVE ACTIONS
//While crawling forward to a passing place on the left, if the road is free and the passing place is just ahead.
//Pull in to the passing place on the left.
+!resolve : crawl_forward(leftPas) & road(_,_,_,has_pass(left)) & pass(X,Y,free,_)
    <-  pullin(X,Y);
        +in_pass(left);
        -crawl_forward(leftPas);
        .wait(1000);
        !resolve.


//While crawling forward to a passing place on the left, if the road is occupied.
//Abandon crawling forward, begin reversing.
/*+!resolve : crawl_forward(leftPas) & road(_,_,occupied(Driver),_)
    <- -crawl_forward(leftPas);
        ?facing(Dir);
        check_behind(1, Dir);
        !reverse;
        !resolve.*/
+!resolve : crawl_forward(leftPas) & road(_,_,occupied(Driver),_)
    <- -crawl_forward(leftPas);
        ?facing(Dir);
        ?vision_dist(Vis);
        check_ahead(Vis, Dir);
        .wait(500);
        !resolve.



//While crawling forward to a passing place on the right, if the road is occupied.
//Abandon crawling forward, begin reversing.
/*+!resolve : crawl_forward(rightPas) & road(_,_,occupied(Driver),_)
    <- -crawl_forward(rightPas);
        ?facing(Dir);
        check_behind(1, Dir);
        !reverse;
        !resolve.*/
+!resolve : crawl_forward(rightPas) & road(_,_,occupied(Driver),_)
    <- -crawl_forward(rightPas);
        ?facing(Dir);
        ?vision_dist(Vis);
        check_ahead(Vis, Dir);
        .wait(500);
        !resolve.

//While crawling forward to a passing place on the right, if the road is free and the passing place is just ahead.
//Stop opposite the passing place.
+!resolve : crawl_forward(rightPas) & road(X,_,free,has_pass(right)) 
    <-  ?facing(Dir);
        move_forward(Dir);
        +opposite_pass;
        -crawl_forward(rightPas);
        .wait(500);
        !resolve.

//While crawling forward
//Take one step forward, and check one space ahead.
+!resolve : crawl_forward(_)
    <-  ?facing(Dir);
        move_forward(Dir);
        check_ahead(1, Dir);
        .wait(500);
        !resolve.


//ORIGINALLY HAD occupied(Driver) IN HERE WHICH CAUSED DEADLOCKS. REVISIT IF NOT WORKING.
//If waiting for a driver to arrive and an oncoming driver approaches.
//Do not wait for the other driver anymore, and wait for the oncoming driver to pass.
+!resolve : not_arrived_yet(Driver) & road(_,_,occupied(_),_)
    <-  -not_arrived_yet(Driver);
        .wait(500);
        !resolve.

//While waiting for driver to arrive and they have not yet arrived.
//Keep waiting and checking ahead
+!resolve : not_arrived_yet(Driver)
    <-  ?facing(Dir);
        ?vision_dist(Vis);
        check_ahead(Vis, Dir);
        !resolve.

//If staying in passing place and the road is no longer occupied.
//Pull out of passing place and resume driving.
+!resolve : in_pass(_) & road(_,_,_,_) & not road(_,_,occupied(Driver),_)
    <-  ?facing(Dir);
        -in_pass(_);
        pullout(Dir);
        -resolving_with(Driver);
        .print("RESUMING DRIVING").

//If staying opposite a passing place and the road is no longer occupied.
//Resume driving.
+!resolve : opposite_pass & road(_,_,_,_) & not road(_,_,occupied(Driver),_)
    <-  -opposite_pass;
        -resolving_with(Driver);
        .print("RESUMING DRIVING").

//If staying opposite a passing place, keep waiting and resolving
+!resolve : opposite_pass
    <-  ?facing(Dir);
        ?vision_dist(Vis);
        check_ahead(Vis, Dir);
        !resolve.

//If staying in a passing place, keep waiting and resolving.
+!resolve : in_pass(_)
    <-  ?facing(Dir);
        ?vision_dist(Vis);
        check_ahead(Vis, Dir);
        !resolve.

//If the road ahead has been cleared up, go back to driving.
+!resolve : not road(_,_,occupied(_),_)
    <-  -resolving_with(_).

//While resolving, if there is a passing place ahead to the left and it is free
//Begin crawling to the passing place.
+!resolve : road(_,_,_,has_pass(left)) & pass(_,_,free,_)
    <- +crawl_forward(leftPas);
    ?facing(Dir);
    check_ahead(1, Dir);
    !resolve.

//While resolving, if there is a passing place ahead to the right
//Begin crawling to the passing place.
+!resolve : road(_,_,_,has_pass(right))
    <- +crawl_forward(rightPas);
    ?facing(Dir);
    check_ahead(1, Dir);
    !resolve.
    

//If standing right next to pass
//Take a step backwards and keep resolving
+!resolve : pass_found(0)
    <-  ?facing(Dir);
        ?vision_dist(Vis);
        move_backward(Dir);
        .wait(500);
        move_backward(Dir);
        .wait(500);
        check_ahead(Vis, Dir);
        .wait(500);
        !resolve.



//If there is no passing place nearby but the road is still occupied.
//Check whether there is a driver behind.
+!resolve : road(_,_,occupied(_),_) & pass_found(_)
    <-  .print("Someone has to reverse. Checking if driver behind...");
        +checking_driver_behind;
        .wait(500);
        ?facing(Dir);
        ?vision_dist(Vis);
        check_behind(Vis, Dir);
        !resolve.

//If there is no known passing place but the road is occupied.
+!resolve : road(_,_,occupied(_),_)
    <-  .print("I do not know of any passing places behind. Waiting on other to reverse");
        .wait(500);
        ?facing(Dir);
        ?vision_dist(Vis);
        check_ahead(Vis, Dir);
        !resolve.

//While resolving, check ahead.
+!resolve
    <-  ?facing(Dir);
        ?vision_dist(Vis);
        check_ahead(Vis, Dir);
        !resolve.



//REVERSING ACTIONS



//While reversing, if there is a driver behind, wait for them to get out of the way.
+!reverse : road(_,_,occupied(New),_) & resolving_with(Driver) & not New=Driver
    <- .wait(500);
        ?facing(Dir);
        check_behind(1, Dir);
        !reverse.

//While reversing, if there is a driver ahead reversing too, and there is a passing place behind
//Begin reversing past the passing place
+!reverse : driver_ahead_reversing & road(_,_,_,has_pass(_))
    <-  -driver_ahead_reversing;
        +reversing_past_pass(2);
        ?facing(Dir);
        move_backward(Dir);
        check_behind(1, Dir);
        !reverse.

//While reversing, if passing place on the left is found and it is free
//Pull in and return to resolving.
+!reverse : road(_,_,_,has_pass(left)) & pass(X,Y,free,_)
    <-  pullin(X,Y);
        .wait(1000);
        ?resolving_with(Driver);
        +waiting_for(Driver);
        +not_arrived_yet(Driver);
        +in_pass(left).

        
//WHile opposite passing place and road is occupied, wait and go back to resolve.
+!reverse : opposite_pass & road(_,_,occupied(_),_)
    <- .wait(500).

//While opposite passing place and the road is cleared, wait for the other driver to catch up and go back to resolve.
//This should just wait for the other driver to catch up and go back to resolve mode.
+!reverse : opposite_pass
    <-  ?resolving_with(Driver);
        +waiting_for(Driver);
        +not_arrived_yet(Driver).

//REVISIT THIS BASED ON QUESTIONNAIRE RESULTS.
//If there is a pass on the right and it is free, pull into it and let the other catch up, then go back to resolving.
+!reverse : road(X,_,_,has_pass(right)) & pass(X,Y,free,_)
    <-  pullin(X,Y);
        .wait(1000);
        ?resolving_with(Driver);
        +waiting_for(Driver);
        +not_arrived_yet(Driver);
        +in_pass(right).

//While reversing, if encountering a passing place on the right, reverse opposite to it and stay opposite the passing place.
+!reverse : road(X,_,_,has_pass(right))
    <-  ?facing(Dir);
        ?vision_dist(Vis);
        move_backward(Dir);
        +opposite_pass;
        check_ahead(Vis, Dir);
        !reverse.

//While reversing past passing place, if the desired distance is reached, go into waiting_for_pass state.
+!reverse : reversing_past_pass(0)
    <-  -reversing_past_pass(_);
        .wait(1000);
        !waiting_for_pass.

//While reversing past passing place, keep making steps back until the distance to reverse back (Dist) reaches 0. This is a recursive method.
+!reverse : reversing_past_pass(Dist)
    <-  .wait(500);
        -reversing_past_pass(Dist);
        +reversing_past_pass(Dist - 1);
        ?facing(Dir);
        move_backward(Dir);
        check_behind(1, Dir);
        !reverse.

//When reversing to a passing place that has another agent in it, reverse past it and wait until it is free. (3 spaces for now).
+!reverse : pass(_,_,occupied(_),_)
    <-  .print("Occupied passing place found. Reversing past it...");
        //We make this into a belief instead of a goal so that the conditions for [when another driver is found while reversing] still applies.
        //We set it to 2 instead of 3 as we already are doing one step back here.
        +reversing_past_pass(2);
        ?facing(Dir);
        move_backward(Dir);
        check_behind(1, Dir);
        !reverse.

//While reversing and the road is clear, move back one space
+!reverse : road(_,_,_,_)
    <-  ?facing(Dir);
        move_backward(Dir);
        !reverse.

//While reversing with no road percepts, check behind one space.
+!reverse 
    <-  ?facing(Dir);
        check_behind(1, Dir);
        !reverse.

//While waiting for pass, if the passing place becomes free, go back to reversing then resolving.
+!waiting_for_pass : pass(_,_,free,_)
    <-  .print("Passing place freed up! Resuming resolving scenario.").

//REVISIT: Possibly do something about free road here too.

//While waiting for pass, keep checking ahead and waiting.
+!waiting_for_pass
    <-  ?facing(Dir);
        ?vision_dist(Vis);
        check_ahead(Vis, Dir);
        .wait(500);
        !waiting_for_pass.




+!wait_for_others : checked(behind) & road(_,_,occupied(Driver),_)
    <-  .wait(500);
        ?facing(Dir);
        ?vision_dist(Vis);
        check_ahead(Vis, Dir);
        -checked(behind);
        +checked(ahead);
        !wait_for_others.

+!wait_for_others : checked(ahead) & road(_,_,occupied(Driver),_)
    <-  .wait(500);
        ?facing(Dir);
        ?vision_dist(Vis);
        check_behind(Vis, Dir);
        -checked(ahead);
        +checked(behind);
        !wait_for_others.

+!wait_for_others : checked(ahead)
    <-  -checked(ahead);
        -resolving_with(_).

+!wait_for_others : checked(behind) & road(_,_,occupied(Driver),_)
    <-  -checked(behind);
        !reverse;
        !resolve.

+!wait_for_others
    <-  .wait(500);
        ?facing(Dir);
        ?vision_dist(Vis);
        check_ahead(Vis, Dir);
        +checked(ahead);
        !wait_for_others.

+!stop <- !stop.
