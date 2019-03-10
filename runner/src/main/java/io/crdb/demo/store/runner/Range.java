package io.crdb.demo.store.runner;

import java.util.ArrayList;
import java.util.List;

public class Range {
    private final int start;
    private final int end;

    public Range(int start, int end) {
        this.start = start;
        this.end = end;
    }

    public int getStart() {
        return start;
    }

    public int getEnd() {
        return end;
    }


    public static List<Range> buildRanges(int totalRecords, int numberOfThreads) {
        int split = totalRecords / numberOfThreads;

        List<Range> ranges = new ArrayList<>(numberOfThreads);

        for (int i = 0; i < numberOfThreads; i++) {
            final int start = i * split;
            final Range range = new Range(start + 1, start + split);
            ranges.add(range);
        }

        return ranges;
    }


    @Override
    public String toString() {
        return "Range{" +
                "start=" + start +
                ", end=" + end +
                '}';
    }
}
