// Agent driverq_hon
//This agent negotiates passing places according to the decision tree gained from the most common approaches in the Driver Behaviour Questionnaire.
//This agent will enter a state of Higher Order Negotiation and discuss a plan with other agents before attempting to resolve.

/* Initial beliefs and rules */
vision_dist(3).
starting_up.
//This is to differentiate between initial facing dir and other agents' facing dir.


/* Initial goals */

!start.

/* Plans */
+!start : true <-   .wait(2000);
                    !drive.

+!start <- !start.

//Initial setting of the facing direction as belief.
+facing(Dir)[source(A)] : not my_name(A) & starting_up
    <-  +facing(Dir);
        -starting_up.

+driver_detected(Other, Dir)[source(A)] : not my_name(A) <- +driver_detected(Other, Dir).

//Handling the response received when asking another vehicle which way they are going.
//Given that agents use the same "facing" belief, in order to not overwrite this agent's facing, we need to keep a separate init_face to remember our alignment:
//  At the end of the method, remove all facing beliefs and re-add the facing belief that matches this agent's init_face.
+resolving_with(Other) : driver_detected(Other, OtherDir) & facing(MyDir) & not OtherDir=MyDir
    <-  .print("DRIVER AHEAD IS ONCOMING!");
        -driver_detected(_,_).


+resolving_with(Other) : driver_detected(Other, Dir) & facing(Dir)
    <-  .print("DRIVER AHEAD IS LEADER!");
        -driver_detected(_,_);
        +following(Other).



//Initial setting of end of road as belief
+roadEnd(X,Y)[source(A)] : not my_name(A) <- +roadEnd(X,Y).


//Convert passing place percept into belief of how far away the last passing place was
+last_pass(_,_,_,_)
    <-  -last_pass(_);
        .print("PASSING PLACE OBTAINED");
        +pass_found(0).




//HIGHER ORDER NEGOTIATION

//This causes more harm than good, possibly remove this altogether.
/*+!hon : enter_hon
    <-  .print("I am already in HON and been told to enter HON");
        -enter_hon;

        //Testing to get rid of the percepts.
        ?facing(Dir);
        ?vision_dist(Vis);
        check_ahead(Vis, Dir);
        !hon.*/

//HANDLING OF MESSAGES FROM OTHERS.
+!hon : enter_hon_resolve_long(Queue_length)[source(Sender)]
    <-  +hon_target_queue_length(Queue_length);
        if(hon_driver_behind_me(Driver)) {
            ?hon_driver_behind_me(Driver);
            .send(Driver,tell,enter_hon_resolve_long(Queue_length));
        }
        .wait(500);
        -enter_hon_resolve_long(_)[source(Sender)];
        !hon_resolve_long.

+!hon : enter_hon_resolve_short(Drivers_behind)
    <-  +hon_target_queue_length(Drivers_behind);
        if(hon_driver_behind_me(Driver)) {
            ?hon_driver_behind_me(Driver);
            .send(Driver,tell,enter_hon_resolve_short(Drivers_behind));
        }
        .wait(500);
        -enter_hon_resolve_short(_)[source(Sender)];
        !hon_resolve_short.

//Had to separate these methods as such as the standby part was important, otherwise the front agents would be stuck in a loop sending the message to each other. 
+!hon : hon_ready_to_negotiate[source(Driver)] & hon_standby_checkdrivers_waitforleader
    <-  .print("WHILE I AM BEHIND, Got message about driver being ready to negotiate. Processing...");
        ?facing(Dir);
        ?vision_dist(Vis);
        check_ahead(Vis, Dir);

        ?road(_,_,occupied(Ahead),_);
        -hon_driver_ahead(_);
        +hon_driver_ahead(Ahead);

        .send(Ahead,tell,hon_ready_to_negotiate);

        -hon_ready_to_negotiate[source(Driver)];
        !hon. 

+!hon : hon_ready_to_negotiate[source(Driver)] & hon_standby_checkdrivers_waitforbehind
    <-  .print("WHILE I AM LEADING, Got message about driver being ready to negotiate. Processing...");
        ?facing(Dir);
        ?vision_dist(Vis);
        check_ahead(Vis, Dir);
        .wait(500);

        ?road(_,_,occupied(Ahead),_);
        -hon_driver_ahead(_);
        +hon_driver_ahead(Ahead);
        
        if(Driver=Ahead) {
            .print("DRIVER AHEAD IS READY. DRIVER DETECTED:");
            .print(Driver);
            +hon_ready_theirside;
        } else {
            .print("DRIVER BEHIND IS READY. DRIVER DETECTED:");
            .print(Driver);
            +hon_ready_myside;
        }
        .send(Ahead,tell,hon_ready_to_negotiate);

        -hon_ready_to_negotiate[source(Driver)];
        !hon. 


+!hon : hon_following_chain(X)[source(Sender)] & not my_name(Sender)
   <-   .print("Got message about drivers I am following. Processing...");
        -hon_following_chain(X)[source(Sender)];
        -hon_following_ahead(_);
        +hon_following_ahead(X);
        !hon.

+!hon : hon_driver_behind_other(Driver)[source(Sender)]
    <- .print("Got message about driver behind other. Processing...");
        ?facing(Dir);
        ?vision_dist(Vis);
        check_ahead(Vis, Dir);

        ?road(_,_,occupied(Ahead),_);
        -hon_driver_ahead(_);
        +hon_driver_ahead(Ahead);
        //Do not need to use the actual Driver data yet but may be good later on.
    
        if (Sender=Ahead) {
            if(hon_drivers_ahead(X)) {
                -hon_drivers_ahead(X);
                +hon_drivers_ahead(X+1);
            } else {
                +hon_drivers_ahead(1);
            }
            
        } else {
            ?hon_drivers_behind(X);
            -hon_drivers_behind(X);
            +hon_drivers_behind(X+1);
            .send(Ahead,tell,hon_driver_behind_other(Driver));
        }
        -hon_driver_behind_other(Driver)[source(Sender)];
        !hon.
    
//CASE FOR PREVIOUSLY FAILED RESOLUTION.
+!hon : should_reverse(equal)
    <-  .print("We are equal. Deciding based on name");
        ?my_name(Me);
        ?failed_to_resolve_with(Other,_);
        -should_reverse(equal);
        if(Me>Other) {
            should_reverse(me);
        } elif (Me<Other) {
            should_reverse(them);
        } else {
            .print("This isn't working. Going to reverse...");
            should_reverse(me);
        }
        !hon.

+!hon : should_reverse(_) & enter_hon[source(A)]
    <-  -enter_hon[source(A)];
        !hon.

+!hon : should_reverse(me)
    <-  .print("I should be the one reversing. Reversing now...");
        ?failed_to_resolve_with(Driver,_);
        +resolving_with(Driver);
        -flashed;
        -should_reverse(_);
        -hon_negotiating(_);
        -failed_to_resolve_with(_,_);
        -other_dist(_);
        -other_side(_);
        -told_other(_);
        .wait(500);
        !reverse.

+!hon : should_reverse(them) & road(_,_,_,_) & not road(_,_,occupied(_),_)
    <-  .print("Other person is reversing! I will exit HON");
        -flashed;
        -should_reverse(_);
        -hon_negotiating(_);
        -failed_to_resolve_with(_,_);
        -other_dist(_);
        -other_side(_);
        -told_other(_);
        .wait(500).

+!hon : should_reverse(them)
    <-  .wait(500);
        .print("Waiting on other person to reverse");
        ?facing(Dir);
        ?vision_dist(Vis);
        check_ahead(Vis, Dir);
        !hon.

+!hon : hon_negotiating & failed_to_resolve_with(Driver, Side) & told_other & other_dist(OtherDist) & other_side(OtherSide)
    <-  .print("Got info from other. Seeing who should reverse.");
        +should_reverse(equal);
        ?pass_found(Dist);
        if(not Dist=OtherDist) {
            -should_reverse(equal);
            if(Dist > OtherDist) {
                -should_reverse(them);
            } else {
                -should_reverse(me);
            }
        }
        if(should_reverse(equal) & not Side=OtherSide) {
            -should_reverse(equal);
            if(other_side(left)) {
                +should_reverse(them);
            } else {
                +should_reverse(me);
            }
        }
        .wait(500);
        !hon.

+!hon : hon_negotiating & failed_to_resolve_with(Driver, Side) & told_other
    <-  .wait(500);
        !hon.

+!hon : hon_negotiating & failed_to_resolve_with(Driver, Side) & hon_driver_ahead(Ahead) & Driver=Ahead
    <-  .print("HON Resolving with driver I have stalemated before. Attempting to share information....");
        .send(Driver,tell,other_side(Side));
        ?pass_found(Dist);
        .send(Driver,tell,other_dist(Dist));
        .wait(500);
        +told_other;
        !hon.

//CASES FOR GETTING STUCK IN LONG QUEUE.


//RESOLUTION FOR LONGER SIDE.:
//Check to see if everyone has passed.
+!hon_resolve_long : hon_long_done[source(A)]
    <-  .print("Leader is driving ahead! Exiting HON, we can drive on.");
        -hon_long_done[source(A)];
        while(enter_hon[source(A)]) {
            -enter_hon[source(A)];
        }
        if(hon_driver_behind_me(Behind)) {
            .send(Behind,tell,hon_long_done);
        }
        -hon_long_backnforth_complete(_);
        -hon_long_current_target(_);
        -hon_target_queue_length(_);
        -hon_long_reversing_target(_);
        .wait(500).

+!hon_resolve_long : hon_long_current_target(0) & hon_long_check_for_completion & road(_,_,occupied(_),_)
    <-  -hon_long_check_for_completion;
        .wait(1000);
        !hon_resolve_long.

+!hon_resolve_long : hon_long_current_target(0) & hon_long_check_for_completion & road(_,_,_,_) & not road(_,_,occupied(_),_)
    <-  .print("Everyone seems to have passed, exiting HON");
        ?facing(Dir);
        move_forward(Dir);
        //CATCH ANY LEFTOVER ENTER_HON
        while(enter_hon[source(A)]) {
            -enter_hon[source(A)];
        }
        if(hon_driver_behind_me(Behind)) {
            .send(Behind,tell,hon_long_done);
        }
        -hon_long_backnforth_complete(_);
        -hon_long_current_target(_);
        -hon_target_queue_length(_);
        -hon_long_reversing_target(_).

+!hon_resolve_long : hon_long_current_target(0) & hon_long_check_for_completion
    <-  .wait(500);
        ?facing(Dir);
        ?vision_dist(Vis);
        check_ahead(Vis, Dir);
        !hon_resolve_long.

//Do X steps forward, where X is the number of cars is the length of the queue
+!hon_resolve_long : hon_long_current_target(0)[source(A)] & my_name(B) & not A=B
    <-  .print("HONLONG: Been told by others to back up. Backing up...");
        .wait(1000);
        if(hon_driver_behind_me(Behind)) {
            .send(Behind,tell,hon_long_current_target(0));
        }
        -hon_long_current_target(0)[source(A)];
        -hon_long_current_target(_);
        !hon_resolve_long.

+!hon_resolve_long : hon_long_current_target(0)[source(A)]
    <-  .print("HONLONG: Backing up...");
        .wait(1000);
        -hon_long_current_target(0)[source(A)];
        !hon_resolve_long.

+!hon_resolve_long : hon_long_current_target(X) & road(_,_,occupied(Driver),_) & hon_following_ahead(0)
    <-  .print("HONLONG: Bumped into driver resolving with. Letting drivers behind know to stop as well");
        -hon_long_current_target(_);
        +hon_long_current_target(0);
        if(hon_driver_behind_me(Behind)) {
            .send(Behind,tell,hon_long_current_target(0));
        }
        !hon_resolve_long.


+!hon_resolve_long : hon_long_current_target(X) & not road(_,_,occupied(_),_)
    <-  ?facing(Dir);
        move_forward(Dir);
        .wait(500);
        -hon_long_current_target(X);
        +hon_long_current_target(X - 1);
        check_ahead(1, Dir);
        !hon_resolve_long.
        
+!hon_resolve_long : hon_long_current_target(X) & not road(_,_,_,_)
    <-  .wait(500);
        ?facing(Dir);
        check_ahead(1, Dir);
        !hon_resolve_long.

//Reversing action to be done after forward action.
+!hon_resolve_long : hon_long_reversing_target(0)
    <-  .wait(1000);
        -hon_long_reversing_target(0);
        !hon_resolve_long.


+!hon_resolve_long : hon_long_reversing_target(X) & road(_,_,_,_) & not road(_,_,occupied(_),_)
    <-  ?facing(Dir);
        move_backward(Dir);
        .wait(500);
        -hon_long_reversing_target(X);
        +hon_long_reversing_target(X - 1);
        !hon_resolve_long.

+!hon_resolve_long : hon_long_reversing_target(X)
    <-  .wait(500);
        ?facing(Dir);
        check_behind(1, Dir);
        !hon_resolve_long.

//Agent returns here once completing a backnforth action
+!hon_resolve_long : hon_target_queue_length(X) & hon_long_backnforth_complete(Y) & hon_other_queue_length(Z) & Y>(Z-1)
    <-  -hon_long_backnforth_complete(Y + Z);
        +hon_long_check_for_completion;
        +hon_long_current_target(X * 2);
        +hon_long_reversing_target(X * 2);
        .wait(500);
        !hon_resolve_long.

+!hon_resolve_long : hon_target_queue_length(X) & hon_long_backnforth_complete(Y)
    <-  -hon_long_backnforth_complete(Y);
        +hon_long_backnforth_complete(Y+1);
        +hon_long_current_target((X + Y + 1) * 2);
        +hon_long_reversing_target((X + Y + 1) * 2);
        .wait(500);
        !hon_resolve_long.

+!hon_resolve_long : hon_target_queue_length(X)
    <-  +hon_long_backnforth_complete(0);
        +hon_long_current_target(X * 2);
        +hon_long_reversing_target(X * 2);
        .wait(500);
        !hon_resolve_long.

//Possibly add "If dont have hon_target_queue_length, try to get it from somewhere (drivers ahead maybe) and then convert it to the belief"
+!hon_resolve_long
    <-  .print("I AM STUCK IN LONG RESOLVE, NOT SURE WHAT TO DO");
        .wait(500);
        ?facing(Dir);
        check_ahead(1, Dir);
        !hon_resolve_long.

//RESOLUTION FOR SHORTER SIDE.:
//-Step forward until a passing place is found.
//-Enter the passing place. Exit HON_resolve_short

+!hon_resolve_short : pass(X,Y,free,Side)
    <-  .print("Found passing place! Pulling in.");
        pullin(X,Y);
        +in_pass(Side);
        .wait(500);
        while(enter_hon[source(A)]) {
            -enter_hon[source(A)];
        }
        .print("Exiting HON and driving on as soon as road clears up").

+!hon_resolve_short : hon_short_approach_pass & not road(_,_,occupied(_),_)
    <-  ?facing(Dir);
        move_forward(Dir);
        .wait(500);
        ?facing(Dir);
        check_ahead(1, Dir);
        !hon_resolve_short.

+!hon_resolve_short : hon_short_approach_pass
    <-  .wait(500);
        ?facing(Dir);
        check_ahead(1, Dir);
        !hon_resolve_short.

//-Stop and wait until the driver in front is not equal to driver_ahead.

+!hon_resolve_short : hon_short_standby & hon_following_ahead(0) & road(_,_,occupied(Driver),_) & hon_driver_ahead(Driver)
    <-  .print("Other queue arrived. Getting ready to approach passing place.");
        -hon_short_standby;
        +hon_short_approach_pass;
        .wait(500);
        ?facing(Dir);
        ?vision_dist(Vis);
        check_ahead(Vis, Dir);
        !hon_resolve_short.

+!hon_resolve_short : hon_short_standby & road(_,_,occupied(Driver),_) & hon_driver_ahead(Ahead) & not Driver=Ahead
    <-  .print("Other queue arrived. Getting ready to approach passing place.");
        -hon_short_standby;
        +hon_short_approach_pass;
        .wait(500);
        ?facing(Dir);
        ?vision_dist(Vis);
        check_ahead(Vis, Dir);
        !hon_resolve_short.

+!hon_resolve_short : hon_short_standby
    <-  .wait(200);
        ?facing(Dir);
        ?vision_dist(Vis);
        check_ahead(Vis, Dir);
        !hon_resolve_short.

//-Step back 2 steps for the number of oncoming cars.

+!hon_resolve_short : hon_short_stepback(0)
    <-  .print("Finished stepping back, waiting to be able to pass");
        -hon_short_stepback(0);
        +hon_short_standby;
        ?facing(Dir);
        ?vision_dist(Vis);
        check_ahead(Vis, Dir);
        !hon_resolve_short.

+!hon_resolve_short : hon_short_stepback(X) & road(_,_,occupied(_),_)
    <-  .wait(500);
        ?facing(Dir);
        check_behind(2, Dir);
        !hon_resolve_short.

+!hon_resolve_short : hon_short_stepback(X)
    <-  ?facing(Dir);
        move_backward(Dir);
        .wait(250);
        move_backward(Dir);
        .wait(250);
        -hon_short_stepback(X);
        +hon_short_stepback(X - 1);
        check_behind(2, Dir);
        !hon_resolve_short.

+!hon_resolve_short
    <-  .wait(500);
        ?hon_other_queue_length(X);
        +hon_short_stepback(X);
        ?facing(Dir);
        check_behind(2, Dir);
        !hon_resolve_short.



//Getting Stuck: Negotiating phase.
//STILL NEED TO HANDLE FURTHER CASES SUCH AS FAR PASSING PLACES AND MULTIPLE PASSING PLACES

+!hon : enter_hon_resolve_short(X)
    <-  .print("Getting ready to perform short-queue resolution.");
        if(hon_driver_behind_me(Driver)) {
            ?hon_driver_behind_me(Driver);
            .send(Driver,tell,enter_hon_resolve_short(X));
        }
        -enter_hon_resolve_short(X);
        +hon_other_queue_length(X);
        .wait(500);
        !hon_resolve_short.

+!hon : enter_hon_resolve_long(X)
    <-  .print("My side is longer! Preparing to do back and forth with drivers behind.");
        if(hon_driver_behind_me(Driver)) {
            ?hon_driver_behind_me(Driver);
            .send(Driver,tell,enter_hon_resolve_long(X));
        }
        -enter_hon_resolve_long(X);
        +hon_other_queue_length(X);
        .wait(1000);
        ?facing(Dir);
        check_ahead(1,Dir);
        !hon_resolve_long.

+!hon : hon_negotiating & hon_drivers_behind(X) & hon_other_queue_length(Y) & X=Y
    <-  .print("Queue sizes are equal! Checking other variables...");
        //Flesh this out more if needed. Future works.
        .wait(5000);
        !hon.

+!hon : hon_negotiating & hon_drivers_behind(X) & hon_other_queue_length(Y) & X<Y
    <-  .print("My side is shorter! Preparing to give space to other queue.");
        if(hon_driver_behind_me(Driver)) {
            ?hon_driver_behind_me(Driver);
            .send(Driver,tell,enter_hon_resolve_short(X));
        }
        .wait(500);
        !hon_resolve_short.

+!hon : hon_negotiating & hon_drivers_behind(X) & hon_other_queue_length(Y) & X>Y
    <-  .print("My side is longer! Preparing to do back and forth with drivers behind.");
        if(hon_driver_behind_me(Driver)) {
            ?hon_driver_behind_me(Driver);
            .send(Driver,tell,enter_hon_resolve_long(X + 1));
        }
        +hon_target_queue_length(X + 1);
        .wait(1000);
        ?facing(Dir);
        check_ahead(1,Dir);
        !hon_resolve_long.

+!hon : hon_negotiating
    <-  .print("Sending other leader my side information.");
        .wait(1000);
        ?hon_driver_ahead(Other);
        ?hon_drivers_behind(X);
        //Passing place side goes here.
        .send(Other,tell,hon_other_queue_length(X));
        !hon.


//Initial setup of counting everyone up.
+!hon : hon_standby_checkdrivers_waitforleader
    <-  //TEMPORARY TEST TO SEE IF AGENT ARRIVES TO THIS CONCLUSION
        .print("I AM IN HON! I AM BEHIND!");
        .wait(1000);
        !hon.

+!hon : hon_standby_checkdrivers_waitforbehind & hon_ready_myside & hon_ready_theirside
    <-  .print("EVERYONE IS READY. BEGINNING TO NEGOTIATE");
        .wait(500);
        -hon_standby_checkdrivers_waitforbehind;
        -hon_ready_myside;
        -hon_ready_theirside;
        +hon_negotiating;
        !hon.

+!hon : hon_standby_checkdrivers_waitforbehind & hon_ready_myside
    <-  //TEMPORARY TEST TO SEE IF AGENT ARRIVES TO THIS CONCLUSION
        .print("I AM IN HON AND READY! WAITING FOR OTHERS TO GET READY!");
        .wait(500);
        !hon.

+!hon : hon_standby_checkdrivers_waitforbehind & hon_following_ahead(0)
    <-  +hon_ready_myside;
        .wait(500);
        !hon.

+!hon : hon_standby_checkdrivers_waitforbehind
    <-  //TEMPORARY TEST TO SEE IF AGENT ARRIVES TO THIS CONCLUSION
        .print("I AM IN HON! I AM AHEAD!");
        .wait(500);
        !hon.


+!hon : hon_look_behind
    <-  .print("I have looked behind. Getting ready to negotiate...");
        -hon_look_behind;
        ?hon_following_ahead(X);
        ?facing(Dir);
        ?vision_dist(Vis);
        check_behind(Vis, Dir);
        .wait(200);

        +hon_pass_behind(0);
        ?hon_driver_ahead(Ahead);
        if (road(_,_,_,has_pass(Side))) {
            -hon_pass_behind(0);
            +hon_pass_behind(1);
        }

        check_behind(Vis, Dir);
        .wait(500);

        if (road(_,_,occupied(Driver),_)) {
            .print("Hon: Driver behind me, I will wait for them");
            +hon_drivers_behind(1);
            .send(Driver,tell,hon_following_chain(X+1));
            .send(Driver,tell,enter_hon);
            +hon_driver_behind_me(Driver);
            .send(Ahead,tell,hon_driver_behind_other(Driver));
            +hon_standby_checkdrivers_waitforbehind;
        } else {
            .print("Hon: Noone behind me, I will be ready to negotiate");
            +hon_drivers_behind(0);
            ?hon_pass_behind(Y);
            .send(Ahead,tell,hon_passes_ahead(Y));
            .send(Ahead,tell,hon_ready_to_negotiate);
        }
        
        if (X > 0) {
            +hon_standby_checkdrivers_waitforleader;
        } else {
            +hon_standby_checkdrivers_waitforbehind;
        }
        !hon.

        
//WILL NEED TO RETURN HERE:
    //GO TO THE TOP AND HANDLE THE FOLLOWING MESSAGES:
    //-hon_Ready_to_negotiate
    //-Hon_driver_behind_other
    //-Hon_following_chain
    //-Hon_passes_ahead




+!hon : hon_look_ahead & hon_following_ahead(X) & X>0
    <-  .print("I have looked ahead and I am following someone who is already in HON. Looking behind now");
        -hon_look_ahead;

        ?facing(Dir);
        ?vision_dist(Vis);
        check_ahead(Vis, Dir);
        .wait(200);

        ?road(_,_,occupied(Driver),_);
        -resolving_with(_);
        -following(_);
        +hon_driver_ahead(Driver);

        +hon_look_behind;
        !hon.

+!hon : hon_look_ahead
    <-  .print("I have looked ahead. looking behind now...");
        -hon_look_ahead;
        +hon_following_ahead(0);

        ?facing(Dir);
        ?vision_dist(Vis);
        check_ahead(Vis, Dir);
        .wait(200);

        if (road(_,_,occupied(Driver),_)) {
            -resolving_with(_);
            +hon_driver_ahead(Driver);
            .send(Driver,tell,enter_hon);
            if(following(Leader) & Driver=Leader) {
                +hon_driver_ahead(Driver);
                -hon_following_ahead(0);
                +hon_following_ahead(1);
            }
        }
        if (road(_,_,_,has_pass(Side))) {
            +hon_pass_between_side(Side);
        }
        if (pass(_,_,occupied(Inpass),_)) {
            +hon_driver_in_pass(Inpass);
        }

        +hon_look_behind;
        !hon.

+!hon
    <-  .print("I have entered HON. Checking ahead now...");
        +hon_drivers_ahead(0);
        +hon_look_ahead;
        !hon.


/*Basic plans for driving, remembering passing places, negotiating passing places*/

//Receiving percept of trying to move to a blocked space, the agent would crash. Send message for crashing and stop the agent fully.
+road_blocked(_)
    <-  .drop_all_desires;
        .print("I HAVE CRASHED!");
        !stop.

//When reaching the end of the road, remove the agent from the road and destroy it.
+!drive : pos(_, X,Y) & roadEnd(X,Y)
    <-  .my_name(A);
        .print("I have reached my destination. Goodbye!");
        //Temporary solution to get agents out of the way
        remove_me;
        .kill_agent(A).

-?reverse : flashed(_)
    <-  -flashed(_);
        .print("I got flashed while not in resolve. Removing flash").

+flashing[source(A)] : flashed_driver(Driver) & A=Driver
    <-  .print("FLASHED WHILE FLASHING! ENTERING HON");
        -flashing;
        flashed_driver(Driver);
        .send(Driver,tell,enter_hon);
        +enter_hon.


+flashing[source(A)]
    <- -flashing;
        .print("I GOT FLASHED!");
        +flashed(A).

+reverse_lights
    <- -reverse_lights;
        .print("DRIVER AHEAD REVERSING!");
        +driver_ahead_reversing.


//LOGIC FOR WHEN ENCOUNTERING ANOTHER VEHICLE.

//While driving and there is another driver ahead that I know is reversing.
//I will stop following the driver, and instead begin resolving. This will make me go to reverse immediately.
+!drive : road(_,_,occupied(Driver),_) & driver_ahead_reversing
    <-  -following(Driver);
        !resolve;
        .print("I am done resolving with reversing driver. Resuming driving.");
        !drive.

//When driving and encountering a driver ahead that I am already following.
//Begin resolving the scenario, but do not ask them which way they are facing.
+!drive : road(_,_,occupied(Driver),_) & following(Driver)
    <-  .print("ENCOUNTERED DRIVER I AM ALREADY FOLLOWING. BEGIN RESOLVING.");
        +resolving_with(Driver);
        ?vision_dist(Vis);
        ?facing(Dir);
        check_ahead(Vis,Dir);
        !resolve;
        !drive.


//When driving and encountering another driver ahead.
//I will first check which way they are facing, then begin resolving the scenario.
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
        +pass_found(1).


//RESOLVE ACTIONS

+!resolve : enter_hon
    <-  .print("Suspending resolve. ENTERING HON");
        -enter_hon;
        !hon;
        !resolve.

//If waiting for a driver to arrive and an oncoming driver approaches.
//Do not wait for the other driver anymore, and wait for the oncoming driver to pass.
+!resolve : not_arrived_yet(Driver) & road(_,_,occupied(_),_)
    <-  -not_arrived_yet(Driver);
        -waiting_counter_in_pass(_);
        .wait(500);
        !resolve.


+!resolve : not_arrived_yet(Driver) & waiting_counter_in_pass(10)
    <-  .print("Other driver never arrived. I will remember this...beginning to move again");
        ?resolving_with(Driver);
        ?in_pass(Side);
        +failed_to_resolve_with(Driver, Side);
        -resolving_with(Driver);
        -not_arrived_yet(Driver);
        -waiting_counter_in_pass(10);
        !resolve.


//While waiting for driver to arrive and they have not yet arrived.
//Keep waiting and checking ahead, also add a counter to waiting.
+!resolve : not_arrived_yet(Driver) & waiting_counter_in_pass(X)
    <-  ?facing(Dir);
        ?vision_dist(Vis);
        .print("Waiting for other driver to arrive");
        .wait(500);
        check_ahead(Vis, Dir);
        -waiting_counter_in_pass(X);
        +waiting_counter_in_pass(X + 1);
        !resolve.

+!resolve : not_arrived_yet(Driver)
    <-  .print("Arrived to passing place. Begin waiting for oncoming driver...");
        +waiting_counter_in_pass(0);
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

+!resolve : flashed(_) & road(_,_,occupied(Driver),_) & pass_found(0)
    <-  .print("Flashed while next to passing place! Reversing past it!");
        -flashed(_);
        -wait_for(_);
        -ask_facing;
        +reversing_past_pass(2);
        ?facing(Dir);
        check_behind(1,Dir);
        !reverse;
        !resolve.

+!resolve : flashed(Other) & road(_,_,occupied(Driver),_) & not Other=Driver & pass_found(_)
    <-  .print("Flashed by driver behind. I will reverse with them.");
        -flashed(_);
        -wait_for(_);
        -ask_facing;
        ?facing(Dir);
        check_behind(1,Dir);
        !reverse;
        !resolve.

+!resolve : flashed(Driver) & road(_,_,occupied(Driver),_) & pass_found(_)
    <-  .print("Road is occupied after getting flashed. Will wait to see if other is moving or wants me to move.");
        -flashed(_);
        +wait_for(3);
        ?vision_dist(Vis);
        ?facing(Dir);
        check_ahead(Vis,Dir);
        !resolve.

+!resolve : flashed(_) & road(_,_,free,_)
    <-  -flashed(_);
        -wait_for(_);
        -ask_facing;
        .print("Road is clear while flashed. Resuming driving!").



+!resolve : flashed(_)
    <-  .print("I got flashed while resolving.");
        .wait(500);
        ?vision_dist(Vis);
        ?facing(Dir);
        check_ahead(Vis,Dir);
        !resolve.

//RESOLVE: WAITING ACTIONS.

//When the wait timer is up and there is still a driver blocking the way, begin reversing.
+!resolve : wait_for(0) & road(_,_,occupied(Driver),_) & pass_found(_)
    <-  .print("No longer waiting. Starting to reverse");
        -wait_for(_);
        .send(Driver,tell,flashing);
        +flashed_driver(Driver);
        ?facing(Dir);
        check_behind(1, Dir);
        !reverse;
        !resolve.

+!resolve : wait_for(0) & road(_,_,occupied(Driver),_) & leader_not_reversing
    <-  .print("Driver ahead seems to be stuck. ENTERING HON");
        -wait_for(_);
        .send(Driver,tell,enter_hon);
        !hon;
        !resolve.


+!resolve : wait_for(0) & road(_,_,occupied(Driver),_)
    <-  .print("I cannot reverse, I must keep waiting...");
        -wait_for(_);
        -driver_ahead_reversing;
        ?vision_dist(Vis);
        ?facing(Dir);
        +leader_not_reversing;
        +wait_for(5);
        check_ahead(Vis, Dir);
        !resolve.


//When waiting and the road is still occupied, take a counter off wait_for and keep checking ahead.
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

//When waiting and there is no agent blocking the road, stop waiting and resume driving.
+!resolve : wait_for(X)
    <-  .print("Other driver began moving. I will follow");
        -flashed(_);
        -wait_for(X).

//If the driver ahead of me is intending to reverse and I remember a passing place, I will reverse.
+!resolve : driver_ahead_reversing & pass_found(_)
    <-  -driver_ahead_reversing;
        -checking_driver_behind;
        -wait_for(_);
        ?facing(Dir);
        check_behind(1,Dir);
        .print("Driver ahead of me is reversing towards me. I will reverse as well.");
        .wait(500);
        !reverse;
        !resolve.

//If the driver ahead of me is intending to reverse but I do not remember any passing places, I will refuse to reverse, and get rid of the driver_ahead_reversing belief.
+!resolve : driver_ahead_reversing
    <-  -failed_to_resolve_with(_);
        -driver_ahead_reversing;
        .print("Driver ahead of me wants to reverse towards me, but I don't know any passing places. I am not reversing.");
        !resolve.

+!resolve : resolving_with(Driver) & failed_to_resolve_with(Driver,_)
    <-  .print("Driver previously failed to resolve with found");
        .print("ENTERING HIGHER ORDER NEGOTIATION");
        .send(Driver,tell,enter_hon);
        !hon.


+!resolve : road(_,_,occupied(Driver),_) & resolving_with(Driver) & following(Driver) & pass_found(Dist)
    <-  .print("Driver ahead of me stopped, I know of a passing place behind. I will wait to see if they move again");
        +wait_for(Dist);
        ?vision_dist(Vis);
        ?facing(Dir);
        check_ahead(Vis,Dir);
        !resolve.

//If resolving with another driver that the agent is already following, wait for 5 seconds to see if they move out of the way.
+!resolve : road(_,_,occupied(Driver),_) & resolving_with(Driver) & following(Driver)
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
        .send(Behind,tell,reverse_lights);
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

//While resolving and looking to check behind for drivers with no obtained information yet, check behind for drivers.
+!resolve : checking_driver_behind
    <-  ?facing(Dir);
        ?vision_dist(Vis);
        check_behind(Vis,Dir);
        !resolve.



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
//Begin resolving with the occupying agent.
+!resolve : crawl_forward(leftPas) & road(_,_,occupied(Driver),_)
    <- -crawl_forward(leftPas);
        ?facing(Dir);
        ?vision_dist(Vis);
        check_ahead(1, Dir);
        .wait(500);
        !resolve.


//While crawling forward to a passing place on the right, if the road is occupied.
//Begin resolving with the occupying agent.
+!resolve : crawl_forward(rightPas) & road(_,_,occupied(Driver),_)
    <- -crawl_forward(rightPas);
        ?facing(Dir);
        ?vision_dist(Vis);
        check_ahead(1, Dir);
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




//If the road ahead has been cleared up, go back to driving.
+!resolve : not road(_,_,occupied(_),_)
    <-  -resolving_with(_).

//While resolving, if there is a passing place ahead to the left and it is free
//Begin crawling to the passing place.
+!resolve : road(_,_,_,has_pass(left)) & pass(_,_,free,_)
    <- ?facing(Dir);
    check_ahead(1, Dir);
    +crawl_forward(leftPas);
    !resolve.

//While resolving, if there is a passing place ahead to the right
//Begin crawling to the passing place.
+!resolve : road(_,_,_,has_pass(right))
    <- ?facing(Dir);
    check_ahead(1, Dir);
    +crawl_forward(rightPas);
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
+!reverse : enter_hon
    <-  .print("Abandoning reverse. ENTERING HON");
        !hon.

+!reverse : flashed
    <-  -flashed;
        !reverse.

//While reversing, if there is a driver behind, wait for them to get out of the way.
//POSSIBLY RETURN HERE: WAIT FOR ANOTHER SECOND OR SO AND ENTER WAIT FOR OTHERS MODE.
+!reverse : road(_,_,occupied(New),_) & resolving_with(Driver) & not New=Driver
    <- .wait(500);
        ?facing(Dir);
        .send(New,tell,reverse_lights);
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
    <-  -pass_found(_);
        -reversing_past_pass(_);
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
+!reverse : pass_found(0)
    <-  .print("initiated reversing while next to a passing place. Reversing past it and resolving.");
        +reversing_past_pass(1);
        !reverse.

//While reversing and the road is clear, move back one space
+!reverse : road(_,_,_,_)
    <-  ?facing(Dir);
        move_backward(Dir);
        ?pass_found(Dist);
        -pass_found(_);
        +pass_found(Dist + 1);
        !reverse.

//While reversing with no road percepts, check behind one space.
+!reverse 
    <-  ?facing(Dir);
        check_behind(1, Dir);
        !reverse.

/* WAITING FOR PASSING PLACE ACTIONS */
//This set of actions will keep waiting behind an occupied passing place until it becomes free.

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


/* WAITING FOR OTHER DRIVERS TO MOVE ACTiONS */
//This set of actions will keep going back and forth between checking the road ahead and checking behind until either the road ahead or road behind is clear.

//If the counter has passed to enter HON, send a message to the driver behind to enter HON. Then enter HON myself.
+!wait_for_others : waiting_counter_for_others(0) & road(_,_,occupied(Driver),_) & checked(behind)
    <-  .send(Driver,tell,enter_hon);
        -checked(behind);
        !hon.

//If the counter has passed to enter HON, send a message to the driver ahead to enter HON.
+!wait_for_others : waiting_counter_for_others(0) & road(_,_,occupied(Driver),_)
    <-  .print("We are stuck! ENTERING HON");
        .send(Driver,tell,enter_hon);
        ?facing(Dir);
        ?vision_dist(Vis);
        check_behind(Vis, Dir);
        -checked(ahead);
        +checked(behind);
        !wait_for_others.


//While the road behind is occupied, keep checking ahead
+!wait_for_others : checked(behind) & road(_,_,occupied(Driver),_)
    <-  .wait(500);
        ?waiting_counter_for_others(X);
        -waiting_counter_for_others(X);
        +waiting_counter_for_others(X-1);
        ?facing(Dir);
        ?vision_dist(Vis);
        check_ahead(Vis, Dir);
        -checked(behind);
        +checked(ahead);
        !wait_for_others.

//While the road ahead is occupied, keep checking behind 
+!wait_for_others : checked(ahead) & road(_,_,occupied(Driver),_)
    <-  .wait(500);
        ?facing(Dir);
        ?vision_dist(Vis);
        check_behind(Vis, Dir);
        -checked(ahead);
        +checked(behind);
        !wait_for_others.

//When there is no agent ahead, stop resolving the scenario with the oncoming driver, and return to driving forward.
+!wait_for_others : checked(ahead)
    <-  -checked(ahead);
        -waiting_counter_for_others(_);
        -resolving_with(_).

//When there is no agent behind, begin reversing, and then resolve the scenario again.
//Usually agents only access reversing from within resolve, but due to the possibility of not having to resolve when the road ahead is clear when in !wait_for_others, it is easier to add resolve after reversing is done here.
+!wait_for_others : checked(behind)
    <-  -checked(behind);
        -waiting_counter_for_others(_);
        !reverse;
        !resolve.

//When waiting for others to move, check ahead first.
+!wait_for_others
    <-  .print("I am completely stuck. Waiting for anyone to move...");
        +waiting_counter_for_others(10);
        .wait(500);
        ?facing(Dir);
        ?vision_dist(Vis);
        check_ahead(Vis, Dir);
        +checked(ahead);
        !wait_for_others.






+!stop <- !stop.
