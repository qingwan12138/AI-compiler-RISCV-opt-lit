#!/usr/bin/env python3
"""Hard-state P0 v3: final 4096-token preflight configuration."""
import sys
import p0_hard_runner_v2 as configured

configured.runner.core.MAX_TOKENS = 4096

if __name__ == "__main__":
    sys.exit(configured.runner.main())
