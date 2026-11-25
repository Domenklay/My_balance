package com.domenklay.mybalance.steps;
final class StepDelta {
    // Short, continuous samples crossing midnight are attributed to the new
    // day; long gaps are deliberately discarded rather than inventing a split.
    static int calculate(long previous,long current,boolean sameDay,boolean nearMidnight,long elapsedMs) {
        if(previous<0||current<previous||elapsedMs<0)return 0;
        if(!sameDay&&(!nearMidnight||elapsedMs>30000))return 0;
        long change=current-previous;
        return change<=100000?(int)change:0;
    }
}
