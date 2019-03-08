package io.crdb.demo.store.runner;

import java.util.ArrayList;
import java.util.List;

public class Range {
    private final int originInclusive;
    private final int boundExclusive;

    public Range(int originInclusive, int boundExclusive) {
        this.originInclusive = originInclusive;
        this.boundExclusive = boundExclusive;
    }

    public int getOriginInclusive() {
        return originInclusive;
    }

    public int getBoundExclusive() {
        return boundExclusive;
    }


    public static List<Range> buildRanges(int numerator, int denominator) {
        int split = numerator / denominator;

        List<Range> ranges = new ArrayList<>(denominator);

        for (int i = 0; i < denominator; i++) {
            final int originInclusive = i * split;
            final Range range = new Range(originInclusive + 1, originInclusive + split);
            ranges.add(range);
        }

        return ranges;
    }


    @Override
    public String toString() {
        return "Range{" +
                "originInclusive=" + originInclusive +
                ", boundExclusive=" + boundExclusive +
                '}';
    }
}
