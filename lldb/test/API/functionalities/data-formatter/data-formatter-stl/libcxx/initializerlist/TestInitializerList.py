"""
Test lldb data formatter subsystem.
"""


import re
import lldb
from lldbsuite.test.decorators import *
from lldbsuite.test.lldbtest import *
from lldbsuite.test import lldbutil


class InitializerListTestCase(TestBase):
    @add_test_categories(["libc++"])
    def test(self):
        """Test that that file and class static variables display correctly."""
        self.build()
        self.runCmd("file " + self.getBuildArtifact("a.out"), CURRENT_EXECUTABLE_SET)

        bkpt = self.target().FindBreakpointByID(
            lldbutil.run_break_set_by_source_regexp(
                self, "Set break point at this line."
            )
        )

        self.runCmd("run", RUN_SUCCEEDED)

        lldbutil.skip_if_library_missing(self, self.target(), re.compile(r"libc\+\+"))

        # The stop reason of the thread should be breakpoint.
        self.expect(
            "thread list",
            STOPPED_DUE_TO_BREAKPOINT,
            substrs=["stopped", "stop reason = breakpoint"],
        )

        self.expect("frame variable ili", substrs=["[1] = 2", "[4] = 5"])
        self.expect(
            "frame variable ils",
            substrs=['[4] = "surprise it is a long string!! yay!!"'],
        )
