// Agent driverhc
//This agent negotiates passing places according to the Highway Code decision tree.

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
+last_pass(X,Y,_,has_pass(Side))
    <-  -last_pass(_);
        .print("PASSING PLACE OBTAINED");
        +last_pass(X,Y, free, has_pass(Side)).


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

+!drive : road(_,_,occupied(D),_)
    <-  .wait(500);
        +resolving_with(D);
        ?vision_dist(Vis);
        ?facing(Dir);
        check_ahead(Vis,Dir);
        !resolve;
        .print("SUCCESSFULLY RESUMED DRIVING");
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

-in_pass(Side)
    <-  -resolving_with(_);
        ?pos(_,X,Y);
        //!!!!!!!Y value hard-coded for now. Would need to implement an if-statement and checking for where the road is later.
        +last_pass(X,1,free,has_pass(Side)).

//crawl_check_roadclear is needed for a specific bug in Scenario 7: 
//If agents see a passing place ahead of themselves and beging crawling forward, they check 1 space in front. But the 2 agents are 2 spaces from each other, and they will step through each other.
+!resolve : crawl_blocked & not road(_,_,occupied(Driver),_)
    <-  .print("Oncoming driver got out of the way! Crawling to passing place.");
        -crawl_blocked;
        ?facing(Dir);
        check_ahead(1, Dir);
        !resolve.

+!resolve : crawl_blocked & road(X,_,occupied(Driver),_) & road(X,_,_,has_pass(left))
    <-  .print("Oncoming driver is waiting at pass! Crawling to passing place.");
        -crawl_blocked;
        ?facing(Dir);
        check_ahead(1, Dir);
        !resolve.

+!resolve : crawl_blocked
    <-  ?facing(Dir);
        ?vision_dist(Vis);
        check_ahead(Vis, Dir);
        .wait(500);
        !resolve.



+!resolve : crawl_check_roadclear & crawl_passDist(P) & crawl_agentDist(A) & A<P
    <-  .print("Road blocked by other agent. Waiting for path to be clear.");
        -crawl_passDist(P);
        -crawl_agentDist(A);
        -crawl_check_roadclear;
        +crawl_blocked;
        ?facing(Dir);
        ?vision_dist(Vis);
        check_ahead(Vis, Dir);
        .wait(500);
        !resolve.

+!resolve : crawl_check_roadclear & pass(X,_,occupied(DriverA),_) & road(X,_,occupied(DriverB),has_pass(_))
    <-  .print("Passing place is being used for resolution. Will stay clear of it.");
        -crawl_passDist(_);
        -crawl_agentDist(_);
        -crawl_check_roadclear;
        +crawl_blocked;
        ?facing(Dir);
        ?vision_dist(Vis);
        check_ahead(Vis, Dir);
        .wait(500);
        !resolve.

+!resolve : crawl_check_roadclear
    <-  .print("Path to passing place is clear. Crawling now.");
        -crawl_agentDist(_);
        -crawl_passDist(_);
        -crawl_check_roadclear;
        ?facing(Dir);
        check_ahead(1, Dir);
        !resolve.


        

+!resolve : crawl_forward(leftPas) & road(_,_,_,has_pass(left)) & pass(X,Y,free,_)
    <-  pullin(X,Y);
        +in_pass(left);
        -crawl_forward(leftPas);
        !resolve.

+!resolve : crawl_forward(leftPas) & road(_,_,_,has_pass(left)) & pass(X,Y,occupied(_),_)
    <-  -crawl_forward(leftPas);
        !resolve.


+!resolve : crawl_forward(leftPas) & road(_,_,occupied(D),_)
    <-  -crawl_forward(leftPas);
        !reverse;
        !resolve.

+!resolve : crawl_forward(rightPas) & road(_,_,occupied(D),_)
    <-  -crawl_forward(rightPas);
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



+!resolve : not_arrived_yet(D) & road(_,_,occupied(D),_)
    <-  -not_arrived_yet(D);
        .wait(500);
        !resolve.

+!resolve : not_arrived_yet(D)
    <-  ?facing(Dir);
        ?vision_dist(Vis);
        check_ahead(Vis, Dir);
        !resolve.

+!resolve : in_pass(left) & road(_,_,_,_) & not road(_,_,occupied(D),_)
    <-  ?facing(Dir);
        -in_pass(left);
        pullout(Dir);
        -resolving_with(D);
        .print("RESUMING DRIVING").

+!resolve : in_pass(right) & road(_,_,_,_) & not road(_,_,occupied(D),_)
    <- -in_pass(right);
        -resolving_with(D);
        .print("RESUMING DRIVING").

+!resolve : in_pass(_)
    <-  ?facing(Dir);
        ?vision_dist(Vis);
        check_ahead(Vis, Dir);
        !resolve.




+!resolve : not road(_,_,occupied(D),_)
    <-  -resolving_with(D).

+!resolve : road(Xp,_,_,has_pass(Side)) & road(Xa,_,occupied(_),_) & pass(_,_,free,_)
    <-  +crawl_check_roadclear;
        if (Side=left) {
            +crawl_forward(leftPas);
        } else {
            +crawl_forward(rightPas);
        }
        ?facing(Dir);
        ?pos(_,Xm,_);
        //Xp is the X of passing place, Xa is the X of other agent, Xm is the X of me.
        //If we are facing left, numbers are descending, so my position will be a higher number than where I am facing. So we make sure to always subtract from the higher number.
        if(Dir=left) {
            DistToPass = Xm - Xp;
            DistToAgent = Xm - Xa; 
        } else {
            DistToPass = Xp - Xm;
            DistToAgent = Xa - Xm; 
        }
        +crawl_passDist(DistToPass);
        +crawl_agentDist(DistToAgent);
        ?vision_dist(Vis);
        check_ahead(Vis, Dir);
        .wait(500);
        !resolve.
    

//If standing right next to pass
+!resolve : last_pass(X,Y,_,_) & pos(_,X,Y)
    <-  ?facing(Dir);
        ?vision_dist(Vis);
        move_backward(Dir);
        check_ahead(Vis, Dir);
        !resolve.

//Right now, the one who knows of a location will instantly reverse, and the one who does not will wait forever, potentially causing a deadlock.
+!resolve : not road(_,_,_,has_pass(_)) & last_pass(_,_,_,_)
    <-  !reverse;
        !resolve.

+!resolve : not road(_,_,_,has_pass(_)) & road(_,_,occupied(D),_)
    <-  ?facing(Dir);
        ?vision_dist(Vis);
        check_ahead(Vis, Dir).

+!resolve
    <-  ?facing(Dir);
        ?vision_dist(Vis);
        check_ahead(Vis, Dir);
        !resolve.

+!reverse : road(_,_,occupied(N),_) & resolving_with(D) & not N=D
    <- .wait(500);
        ?facing(Dir);
        check_behind(1, Dir);
        !reverse.

+!reverse : road(_,_,_,has_pass(left)) & pass(X,Y,free,_)
    <-  pullin(X,Y);
        ?resolving_with(D);
        +waiting_for(D);
        +not_arrived_yet(D);
        +in_pass(left).

        

+!reverse : in_pass(right) & road(_,_,occupied(_),_)
    <- .wait(500).

//This should just wait for the other driver to catch up and go back to resolve mode.
+!reverse : in_pass(right) 
    <-  ?resolving_with(D);
        +waiting_for(D);
        +not_arrived_yet(D).

//If there is a pass on the right, move back 1 space to be parallel and let the other catch up. Go back to 
+!reverse : road(X,_,_,has_pass(right)) & not pass(X,_,occupied(_),_)
    <-  ?facing(Dir);
        ?vision_dist(Vis);
        move_backward(Dir);
        +in_pass(right);
        check_ahead(Vis, Dir);
        !reverse.

+!reverse : road(_,_,_,_)
    <-  ?facing(Dir);
        move_backward(Dir);
        !reverse.

+!reverse 
    <-  ?facing(Dir);
        check_behind(1, Dir);
        !reverse.

+!stop <- !stop.
