// Agent driverquestion
//This agent negotiates passing places according to the Questionnaire results and questionnaire decision tree.

/* Initial beliefs and rules */
vision_dist(3).


/* Initial goals */

!start.

/* Plans */
+!start : true <-   .wait(2000);
                    !drive.

+!start <- !start.



/*Convert initial percepts into beliefs*/
+facing(Dir)[source(A)] : not my_name(A) <- +facing(Dir).

+roadEnd(X,Y)[source(A)] : not my_name(A) <- +roadEnd(X,Y).

/*Convert passing place percept into belief*/
+last_pass(_,_,_,_)
    <-  -last_pass(_);
        .print("PASSING PLACE OBTAINED");
        +last_pass(0).


+flashing
    <- -flashing;
        .print("I GOT FLASHED!");
        +flashed.


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

+!drive : road(_,_,occupied(Driver),_)
    <-  .wait(500);
        +resolving_with(Driver);
        ?vision_dist(Vis);
        ?facing(Dir);
        check_ahead(Vis,Dir);
        !resolve;
        .print("SUCCESSFULLY RESUMED DRIVING");
        !drive.


+!drive : road(_,_,free,_) & last_pass(_)
    <-  ?facing(Dir);
        move_forward(Dir);
        ?last_pass(Dist);
        +last_pass(Dist + 1);
        !drive.


+!drive : road(_,_,free,_) 
    <-  ?facing(Dir);
        move_forward(Dir);
        !drive.

+!drive : not road(_,_,_,_)
    <-  ?vision_dist(Vis);
        ?facing(Dir);
        check_ahead(Vis,Dir);
        !drive.

+!drive <- !drive.

-in_pass(_)
    <-  -resolving_with(_);
        ?pos(_,X,Y);
        //!!!!!!!Y value hard-coded for now. Would need to implement an if-statement and checking for where the road is later.
        +last_pass(0).

//FLASHED ACTIONS : RESOLVE
+!resolve : flashed & pass(_,_,free,left)
    <-  +crawl_forward(leftPas);
        -flashed;
        !resolve.

+!resolve : flashed & pass(_,_,free,right)
    <-  +crawl_forward(rightPas);
        -flashed;
        !resolve.

+!resolve : flashed & driver_behind(Behind)
    <-  -flashed;
        .print("Turning reverse lights on...Reversing...");
        .send(Behind,tell,reverse_lights);
        .wait(1000);
        !reverse;
        !resolve.

+!resolve : flashed & road(_,_,occupied(_),_)
    <-  -flashed;
        .print("Flashed, no pass and no driver behind. Reversing...");
        !reverse;
        !resolve.

+!resolve : flashed & not road(_,_,occupied(_),_)
    <-  .print("No drivers ahead after being flashed. Resuming...")
        -flashed.

+!resolve : flashed_checked_behind & road(_,_,occupied(Driver),_)
    <-  +driver_behind(Driver);
        -flashed_checked_behind;
        ?vision_dist(Vis);
        ?facing(Dir);
        check_ahead(Vis, Dir);
        !resolve.


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
    <-  .print("I am about to reverse. Flashing other to follow");
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
+!resolve : checking_driver_behind & last_pass(Dist)
    <-  -checking_driver_behind;
        .send("I know a passing place behind. Waiting to see if other reverses.");
        wait(Dist * 500);
        +about_to_reverse;
        !resolve.

//No driver behind, but no known passing place.
//The agent waits to see if the other reverses first, and so goes back to resolve. If the other person still waits, it will come back here, but now to the "about_to_reverse" option above.
+!resolve : checking_driver_behind
    <-  -checking_driver_behind;
        .send("I haven't seen any passing place. Waiting to see if other reverses.");
        wait(5000);
        +about_to_reverse;
        !resolve.



//REMAINING RESOLVE ACTIONS
+!resolve : crawl_forward(leftPas) & road(_,_,_,has_pass(left)) & pass(X,Y,free,_)
    <-  pullin(X,Y);
        +in_pass(left);
        -crawl_forward(leftPas);
        !resolve.


+!resolve : crawl_forward(leftPas) & road(_,_,occupied(Driver),_)
    <- -crawl_forward(leftPas);
        !reverse;
        !resolve.

+!resolve : crawl_forward(rightPas) & road(_,_,occupied(Driver),_)
    <- -crawl_forward(rightPas);
        !reverse;
        !resolve.

+!resolve : crawl_forward(rightPas) & road(X,_,free,has_pass(right)) 
    <-  ?facing(Dir);
        move_forward(Dir);
        +in_pass(right);
        -crawl_forward(rightPas);
        !resolve.

+!resolve : crawl_forward(_)
    <-  ?facing(Dir);
        move_forward(Dir);
        check_ahead(1, Dir);
        !resolve.



+!resolve : not_arrived_yet(Driver) & road(_,_,occupied(Driver),_)
    <-  -not_arrived_yet(Driver);
        .wait(500);
        !resolve.

+!resolve : not_arrived_yet(Driver)
    <-  ?facing(Dir);
        ?vision_dist(Vis);
        check_ahead(Vis, Dir);
        !resolve.

+!resolve : in_pass(left) & road(_,_,_,_) & not road(_,_,occupied(Driver),_)
    <-  ?facing(Dir);
        -in_pass(left);
        pullout(Dir);
        -resolving_with(Driver);
        .print("RESUMING DRIVING").

+!resolve : in_pass(right) & road(_,_,_,_) & not road(_,_,occupied(Driver),_)
    <- -in_pass(right);
        -resolving_with(Driver);
        .print("RESUMING DRIVING").

+!resolve : in_pass(_)
    <-  ?facing(Dir);
        ?vision_dist(Vis);
        check_ahead(Vis, Dir);
        !resolve.

+!resolve : not road(_,_,occupied(_),_)
    <-  -resolving_with(_).


+!resolve : road(_,_,_,has_pass(left)) & pass(_,_,free,_)
    <- +crawl_forward(leftPas);
    ?facing(Dir);
    check_ahead(1, Dir);
    !resolve.

+!resolve : road(_,_,_,has_pass(right))
    <- +crawl_forward(rightPas);
    ?facing(Dir);
    check_ahead(1, Dir);
    !resolve.
    

//If standing right next to pass
+!resolve : last_pass(0)
    <-  ?facing(Dir);
        ?vision_dist(Vis);
        move_backward(Dir);
        check_ahead(Vis, Dir);
        !resolve.



//If there is no passing place nearby but the road is still occupied.
+!resolve : not road(_,_,_,has_pass(_)) & road(_,_,occupied(_),_)
    <-  .print("Someone has to reverse. Checking if driver behind...");
        +checking_driver_behind;
        ?facing(Dir);
        ?vision_dist(Vis);
        check_behind(Vis, Dir);
        !resolve.

+!resolve
    <-  ?facing(Dir);
        ?vision_dist(Vis);
        check_ahead(Vis, Dir);
        !resolve.

+!reverse : road(_,_,occupied(New),_) & resolving_with(Driver) & not New=Driver
    <- .wait(500);
        ?facing(Dir);
        check_behind(1, Dir);
        !reverse.


+!reverse : road(_,_,_,has_pass(left)) & pass(X,Y,free,_)
    <-  pullin(X,Y);
        ?resolving_with(Driver);
        +waiting_for(Driver);
        +not_arrived_yet(Driver);
        +in_pass(left).

        

+!reverse : in_pass(right) & road(_,_,occupied(_),_)
    <- .wait(500).

//This should just wait for the other driver to catch up and go back to resolve mode.
+!reverse : in_pass(right) 
    <-  ?resolving_with(Driver);
        +waiting_for(Driver);
        +not_arrived_yet(Driver).

//REVISIT THIS BASED ON QUESTIONNAIRE RESULTS.
//If there is a pass on the right, move back 1 space to be parallel and let the other catch up. Go back to 
+!reverse : road(X,_,_,has_pass(right)) & not pass(X,_,occupied(_),_)
    <-  ?facing(Dir);
        ?vision_dist(Vis);
        move_backward(Dir);
        +in_pass(right);
        check_ahead(Vis, Dir);
        !reverse.

+!reverse : +reversing_past_pass(0)
    <-  -reversing_past_pass(_);
        .wait(1000);
        !waiting_for_pass.

+!reverse : +reversing_past_pass(Dist)
    <-  -reversing_past_pass(Dist)
        +reversing_past_pass(Dist - 1)
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

+!reverse : road(_,_,_,_)
    <-  ?facing(Dir);
        move_backward(Dir);
        !reverse.

+!reverse 
    <-  ?facing(Dir);
        check_behind(1, Dir);
        !reverse.

+!waiting_for_pass : pass(_,_,free,_)
    <-  .print("Passing place freed up! Resuming resolving scenario.");

//REVISIT: Possibly do something about free road here too.

+!waiting_for_pass
    <-  ?facing(Dir);
        ?vision_dist(Vis);
        check_ahead(Vis, Dist);
        .wait(500);
        !waiting_for_pass.

+!stop <- !stop.
