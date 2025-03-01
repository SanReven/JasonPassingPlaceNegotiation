// Agent drivercomm
//This agent negotiates passing places according to an expanded version of the Highway Code decision tree that includes communication via signals

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

+road_blocked(_)
    <-  .drop_all_desires;
        .print("I HAVE CRASHED!");
        !stop.

//Communication bits added

//Flash method 1: Detect Flash alone. !!Warning. .drop_intention seems to drop the entire chain of intentions for some reason
/*+flash
    <-  .drop_intention(reverse);
        .drop_intention(resolve);
        -resolving_with(_);
        !drive.*/

//Flash method 2: overwrite specific intentions.
//Just finish reverse intention and go back to resolve.
+!reverse : flash.

//drop the resolving_with belief, finish resolve intention and return to driving 
+!resolve : flash
    <-  -flash[source(_)].

//Indicate method 1: Detect Flash alone. !!Warning. .drop_intention seems to drop the entire chain of intentions for some reason
/*+indicate_left
    <-  .drop_intention(resolve);
        -resolving_with(_);
        !drive.*/

//Indicate method 2: overwrite specific intentions. 
//drop the resolving_with belief, finish resolve intention and return to driving
+!resolve : indicate_left
    <-  -indicate_left[source(_)];
        ?resolving_with(D);
        -resolving_with(D).

+!resolve : OtherAgentReversing == true
    <-  +resolving_with(D);
        -OtherAgentReversing;
        !reverse.

+!resolve : OtherAgentReversing == false
    <- -OtherAgentReversing.


//Basic plans for driving, remembering passing places, negotiating passing places
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
        .send(D, askOne, facing(X), OtherAgentFacing);
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
        +last_pass(X,Y,free,has_pass(Side)).



+!resolve : OtherAgentFacing == facing(X) & facing(Y) & X==Y
    <-  .send(D, askOne, reverse_light_on, OtherAgentReversing);
    -OtherAgentFacing;
    !resolve.



+!resolve : crawl_forward(leftPas) & road(_,_,_,has_pass(left)) & pass(X,Y,free,_)
    <-  pullin(X,Y);
        +in_pass(left);
        -crawl_forward(leftPas);
        !resolve.


+!resolve : crawl_forward(leftPas) & road(_,_,occupied(D),_)
    <- -crawl_forward(leftPas);
        +reverse_light_on;
        .send(D,tell,flash);
        !reverse;
        !resolve.

+!resolve : crawl_forward(rightPas) & road(_,_,occupied(D),_)
    <- -crawl_forward(rightPas);
        +reverse_light_on;
        .send(D,tell,flash);
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



+!resolve : not_arrived_yet & road(_,_,occupied(D),_)
    <-  -not_arrived_yet;
        .wait(500);
        !resolve.

+!resolve : not_arrived_yet
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


+!resolve : road(_,_,_,has_pass(left)) & pass(_,_,free,_)
    <- ?resolving_with(D);
    .send(D, tell, indicate_left);
    +crawl_forward(leftPas);
    ?facing(Dir);
    check_ahead(1, Dir);
    !resolve.

+!resolve : road(_,_,_,has_pass(right))
    <- +crawl_forward(rightPas);
    ?facing(Dir);
    check_ahead(1, Dir);
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
    <-  ?resolving_with(D);
        .send(D,tell,flash);
        +reverse_light_on;
        !reverse;
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

+!reverse : road(_,_,occupied(N),_) & resolving_with(D) & not N == D & not not_arrived_yet
    <- .wait(500);
        ?facing(Dir);
        check_behind(Dir);
        !reverse.

+!reverse : road(X,_,_,has_pass(left)) & pass(X,Y,free,_)
    <-  pullin(X,Y);
        +not_arrived_yet;
        -reverse_light_on;
        +in_pass(left).

        

+!reverse : in_pass(right) & road(_,_,occupied(_),_)
    <- .wait(500).

//This should just wait for the other driver to catch up and go back to resolve mode.
+!reverse : in_pass(right) 
    <-  +not_arrived_yet.

//If there is a pass on the right, move back 1 space to be parallel and let the other catch up. Go back to 
+!reverse : road(X,_,_,has_pass(right)) & pass(X,_,free,_)
    <-  ?facing(Dir);
        ?vision_dist(Vis);
        move_backward(Dir);
        +in_pass(right);
        -reverse_light_on;
        check_ahead(Vis, Dir);
        !reverse.

+!reverse : road(_,_,_,_)
    <-  ?facing(Dir);
        move_backward(Dir);
        check_behind(Dir);
        !reverse.

+!reverse 
    <-  ?facing(Dir);
        check_behind(Dir);
        !reverse.

+!stop <- !stop.
