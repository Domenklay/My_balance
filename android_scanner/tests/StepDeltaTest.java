package com.domenklay.mybalance.steps;
public final class StepDeltaTest {
    static void check(int actual,int expected){if(actual!=expected)throw new AssertionError(actual+" != "+expected);}
    public static void main(String[] args){
        check(StepDelta.calculate(100,105,true,false,5000),5);
        check(StepDelta.calculate(100,105,false,true,8000),5);
        check(StepDelta.calculate(100,105,false,true,30001),0);
        check(StepDelta.calculate(100,105,false,false,8000),0);
        check(StepDelta.calculate(-1,105,true,false,8000),0);
        check(StepDelta.calculate(100,2,true,false,8000),0);
        check(StepDelta.calculate(100,105,true,false,-1),0);
        System.out.println("PASS native step delta: continuous midnight, stale gap and reset");
    }
}
