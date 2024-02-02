from huey import signals as _huey_signals


# We need the information at which point a task is "finished"
# and no longer waits or runs, etc.
# It does not mean that execution was successfully completed!
#

TASK_MODEL_DESC_MAX_LENGTH = 128

ISSUE_HUEY_SIGNALS = [
    _huey_signals.SIGNAL_CANCELED,
    _huey_signals.SIGNAL_ERROR,
    _huey_signals.SIGNAL_EXPIRED, # signal was retired in huey
    _huey_signals.SIGNAL_REVOKED,
    _huey_signals.SIGNAL_INTERRUPTED,
]
# ['canceled', 'error', 'revoked', 'interrupted']

ENDED_HUEY_SIGNALS = ISSUE_HUEY_SIGNALS + [
    _huey_signals.SIGNAL_COMPLETE,
]
# ['canceled', 'error', 'revoked', 'interrupted', 'complete']