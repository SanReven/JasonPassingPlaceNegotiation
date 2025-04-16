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



+facing(OtherDir)[source(A)] : not my_name(A) & expecting_response
    <-  +other_facing(OtherDir);
        ?init_face(MyDir);
        -facing(_);
        +facing(MyDir);
        .print("DRIVER AHEAD GOING THIS WAY: ");
        .print(OtherDir);
        -expecting_response.

/*Convert initial percepts into beliefs*/
+facing(Dir)[source(A)] : not my_name(A)
    <-  +facing(Dir);
        //Backup of facing direction
        +init_face(Dir).

+roadEnd(X,Y)[source(A)] : not my_name(A) <- +roadEnd(X,Y).

/*Convert passing place percept into belief*/
+last_pass(_,_,_,_)
    <-  -last_pass(_);
        .print("PASSING PLACE OBTAINED");
        +pass_found(0).


+flashing
    <- -flashing;
        .print("I GOT FLASHED!");
        +flashed.

+reverse_lights
    <- -reverse_lights;
        .print("DRIVER AHEAD REVERSING!");
        +driver_ahead_reversing.

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
//I will wait a second then continue driving.
+!drive : road(_,_,occupied(Driver),_) & following(Driver)
    <-  .wait(1000);
        !drive.

//While driving and there is another driver ahead and we are both facing the same way.
//I will begin following the driver ahead and keep driving.
+!drive : road(_,_,occupied(Driver),_) & other_facing(Dir) & facing(Dir)
    <-  .wait(500);
        +following(Driver);
        -other_facing(_);
        .print("I will begin following!");
        //RETURN TO THIS
        //move_forward(Dir);
        !drive.

//While driving and there is another driver ahead that is facing towards me.
//I will cheack ahead again then begin resolving the scenario with the driver ahead.
+!drive : road(_,_,occupied(Driver),_) & other_facing(_)
    <-  .wait(500);
        +resolving_with(Driver);
        -other_facing(_);
        ?vision_dist(Vis);
        ?facing(Dir);
        check_ahead(Vis,Dir);
        //Random wait time
        //RETURN TO THIS, REMOVE THIS RANDOMNESS AND MOVE IT TO HIGHER ORDER.
        .random(Rand);
        .wait(Rand * 200);
        !resolve;
        .print("SUCCESSFULLY RESUMED DRIVING");
        !drive.

//While driving and there is a driver ahead and I am waiting for a response from the driver ahead to see which way they are facing via the plan below.
//I will keep waiting.
+!drive : road(_,_,occupied(Driver),_) & expecting_response
    <-  .wait(500);
        !drive.

//When driving and encountering another driver ahead.
//Check whether they are an oncoming driver, or I have caught up to a driver going the same way.
//I do this by sending them a message and ask them about their belief of which way they are facing. I expect them to send their facing(Dir) belief back.
+!drive : road(_,_,occupied(Driver),_)
    <-  +expecting_response;
        .send(Driver, askOne, facing(Dir));
        !drive.


//While driving on a clear road and I know of a passing place behind, move forward and increase the distance it is away from me.
+!drive : road(_,_,free,_) & pass_found(_)
    <-  ?facing(Dir);
        move_forward(Dir);
        ?pass_found(Dist);
        -pass_found(_);
        +pass_found(Dist + 1);
        !drive.

//While driving and I know the road is clear, take a step forward.
+!drive : road(_,_,free,_) 
    <-  ?facing(Dir);
        move_forward(Dir);
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
        +pass_found(0).

//When leaving a passing place that I pulled into.
//Note that passing place as a past passing place.
-in_pass(_)
    <-  -resolving_with(_);
        ?pos(_,X,Y);
        //!!!!!!!Y value hard-coded for now. Would need to implement an if-statement and checking for where the road is later.
        +pass_found(0).

//DRIVER AHEAD REVERSING ACTIONS: RESOLVE.

/*
//RETURN TO THIS
//When resolving and the driver ahead is reversing but the road ahead is no longer blocked.
//Forget about the driver ahead reversing and keep resolving. (They have gotten out of the way, most likely 
+!resolve : driver_ahead_reversing & not road(_,_,occupied(_),_)
    <-  -driver_ahead_reversing;
        !resolve.*/

/*
//RETURN TO THIS
//When resolving, while the driver ahead is reversing and there is a passing place next to me.
//Take a step backwards and go back to resolve (reasses the scenario)
+!resolve : driver_ahead_reversing & last_pass(0)
    <-  -driver_ahead_reversing;
        ?facing(Dir);
        move_backward(Dir);
        !resolve.*/

/*
//RETURN TO THIS
//When resolving and the driver ahead is reversing and there is a free passing place.
//Move back to opposite the passing place
+!resolve : driver_ahead_reversing & pass(_,_,free,_)
    <-  -driver_ahead_reversing;
        ?facing(Dir);
        move_backward(Dir);
        !resolve.*/

//If the driver ahead is reversing, go straight to reversing as well
+!resolve : driver_ahead_reversing
    <-  !reverse;
        !resolve.



//FLASHED ACTIONS : RESOLVE
//If processing the other person's flashing while already opposite a passing place, ignore the flash.
+!resolve : flashed & opposite_pass
    <-  .print("Flashed while opposite pass. Ignoring.");
        -flashed;
        !resolve.

//If processing the other person's flashing while already in a passing place, ignore the flash.
+!resolve : flashed & in_pass(_)
    <-  .print("Flashed while in pass. Ignoring.");
        -flashed;
        !resolve.

//If flashed and there is a free passing place to the left
//crawl forward to the passing place on the left.
//They probably want me to get out of the way, since they did not pull in themselves but flashed.
+!resolve : flashed & pass(_,_,free,left)
    <-  +crawl_forward(leftPas);
        -flashed;
        !resolve.

//RETURN TO THIS.
//If flashed and there is a free passing place to the right
//crawl forward to the passing place on the right.
//They probably want me to get out of the way, since they did not pull in themselves but flashed.
+!resolve : flashed & pass(_,_,free,right)
    <-  +crawl_forward(rightPas);
        -flashed;
        !resolve.

//If flashed and there is a driver behind, send the driver behind a message that I am turning on my reverse lights, and begin reversing.
//To signal that I am reversing, I am turning on my reverse lights, like the questionnaire shows. The only way to communicate this is via .send message.
+!resolve : flashed & driver_behind(Behind)
    <-  -flashed;
        .print("Turning reverse lights on...Reversing...");
        .send(Behind,tell,reverse_lights);
        .wait(1000);
        !reverse;
        !resolve.

//If flashed and there is noone behind and no passing place around, begin reversing.
+!resolve : flashed & road(_,_,occupied(_),_)
    <-  -flashed;
        .print("Flashed, no pass and no driver behind. Reversing...");
        !reverse;
        !resolve.

//If flashed but there is noone around by the time of processing, ignore the flash.
+!resolve : flashed & not road(_,_,occupied(_),_)
    <-  .print("No drivers ahead after being flashed. Resuming...");
        -flashed.

//If flashed and checked behind already, and there is a driver, note that there is a driver behind me. keep resolving.
+!resolve : flashed_checked_behind & road(_,_,occupied(Driver),_)
    <-  +driver_behind(Driver);
        -flashed_checked_behind;
        ?vision_dist(Vis);
        ?facing(Dir);
        check_ahead(Vis, Dir);
        !resolve.

//If flashed while resolving, check if there is another car behind me
+!resolve : flashed
    <-  -checking_driver_behind;
        ?vision_dist(Vis);
        ?facing(Dir);
        check_behind(Vis, Dir);
        +flashed_checked_behind;
        !resolve.


//RESOLVE ACTIONS DEPENDING ON DRIVER BEHIND

//If the agent decided to reverse and wait, and the driver ahead was still waiting, the agent will end up here.
//The agent will flash the other driver to follow them and reverse.
+!resolve : checking_driver_behind & about_to_reverse
    <-  -checking_driver_behind;
        .print("I am about to reverse. Flashing other to follow");
        ?resolving_with(Driver);
        .send(Driver,tell,flashing);
        !reverse;
        !resolve.


//Driver behind found. Flashing other person to reverse.
+!resolve : checking_driver_behind & road(_,_,occupied(Behind),_)
    <-  -checking_driver_behind;
        //+driver_behind(Behind); REVISIT. Uncomment this if doing wait_for_other_reverse condition.
        ?resolving_with(Driver);
        .wait(500);
        .print("Driver found behind...flashing other driver");
        .send(Driver,tell,flashing);
        //REVISIT. Possibly add +wait_for_other_reverse here.
        .wait(3000).

//No driver behind, known passing place.
//The agent waits to see if the other reverses first, and so goes back to resolve. If the other person still waits, it will come back here, but now to the "about_to_reverse" option above.
+!resolve : checking_driver_behind & pass_found(Dist)
    <-  -checking_driver_behind;
        .print("I know a passing place behind. Waiting to see if other reverses.");
        .wait(Dist * 200);
        //Also wait a random amount of time. MOVE THIS LATER TO A MORE COMMON ACTION
        //.random(Rand);
        //.wait(Rand * 1000);
        +about_to_reverse;
        ?facing(Dir);
        ?vision_dist(Vis);
        check_ahead(Vis,Dir);
        !resolve.

//No driver behind, but no known passing place.
//The agent waits to see if the other reverses first, and so goes back to resolve. If the other person still waits, it will come back here, but now to the "about_to_reverse" option above.
+!resolve : checking_driver_behind
    <-  -checking_driver_behind;
        .print("I haven't seen any passing place. Waiting to see if other reverses.");
        .wait(2000);
        //Also wait a random amount of time. MOVE THIS LATER TO A MORE COMMON ACTION
        //.random(Rand);
        //.wait(Rand * 100);
        +about_to_reverse;
        ?facing(Dir);
        ?vision_dist(Vis);
        check_ahead(Vis,Dir);
        !resolve.



//REMAINING RESOLVE ACTIONS
//While crawling forward to a passing place on the left, if the road is free and the passing place is just ahead.
//Pull in to the passing place on the left.
+!resolve : crawl_forward(leftPas) & road(_,_,_,has_pass(left)) & pass(X,Y,free,_)
    <-  pullin(X,Y);
        +in_pass(left);
        -crawl_forward(leftPas);
        !resolve.


//While crawling forward to a passing place on the left, if the road is occupied.
//Abandon crawling forward, begin reversing.
+!resolve : crawl_forward(leftPas) & road(_,_,occupied(Driver),_)
    <- -crawl_forward(leftPas);
        !reverse;
        !resolve.

//While crawling forward to a passing place on the right, if the road is occupied.
//Abandon crawling forward, begin reversing.
+!resolve : crawl_forward(rightPas) & road(_,_,occupied(Driver),_)
    <- -crawl_forward(rightPas);
        !reverse;
        !resolve.

//While crawling forward to a passing place on the right, if the road is free and the passing place is just ahead.
//Stop opposite the passing place.
+!resolve : crawl_forward(rightPas) & road(X,_,free,has_pass(right)) 
    <-  ?facing(Dir);
        move_forward(Dir);
        +opposite_pass;
        -crawl_forward(rightPas);
        !resolve.

//While crawling forward
//Take one step forward, and check one space ahead.
+!resolve : crawl_forward(_)
    <-  ?facing(Dir);
        move_forward(Dir);
        check_ahead(1, Dir);
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
        check_ahead(Vis, Dir);
        !resolve.



//If there is no passing place nearby but the road is still occupied.
//Check whether there is a driver behind.
+!resolve : not road(_,_,_,has_pass(_)) & road(_,_,occupied(_),_)
    <-  .print("Someone has to reverse. Checking if driver behind...");
        +checking_driver_behind;
        ?facing(Dir);
        ?vision_dist(Vis);
        check_behind(Vis, Dir);
        !resolve.

//While resolving, check ahead.
+!resolve
    <-  ?facing(Dir);
        ?vision_dist(Vis);
        check_ahead(Vis, Dir);
        !resolve.






//If flashed while reversing, go back to resolving.
+!reverse : flashed
    <-  -flashed;
        .print("I have been flashed while reversing! Resuming resolving...").

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
    <-  -reversing_past_pass(Dist);
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

+!stop <- !stop.
