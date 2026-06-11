package transaction

import "fmt"

var transitions = map[State]map[State]bool{
	StatePlanned: {
		StatePreflighted: true,
		StateAborted:     true,
	},
	StatePreflighted: {
		StateSnapshotCreated: true,
		StateAborted:         true,
	},
	StateSnapshotCreated: {
		StateJournalOpened: true,
		StateAborted:       true,
	},
	StateJournalOpened: {
		StateMutationStarted: true,
		StateAborted:         true,
	},
	StateMutationStarted: {
		StateMutationApplied: true,
		StateRollbackStarted: true,
	},
	StateMutationApplied: {
		StatePostflightStarted: true,
		StateRollbackStarted:   true,
	},
	StatePostflightStarted: {
		StateCommitted:       true,
		StateRollbackStarted: true,
	},
	StateRollbackStarted: {
		StateRolledBack:      true,
		StateRollbackPartial: true,
		StateRollbackFailed:  true,
	},
}

func ValidTransition(from, to State) bool {
	return transitions[from][to]
}

func validateTransition(from, to State) error {
	if !ValidTransition(from, to) {
		return fmt.Errorf("invalid transaction transition %q -> %q", from, to)
	}
	return nil
}
