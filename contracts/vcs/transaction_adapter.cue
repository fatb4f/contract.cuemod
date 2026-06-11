package vcs

#AdapterMethodName:
	"ID" |
	"State" |
	"Open" |
	"Preflight" |
	"Snapshot" |
	"Journal" |
	"Apply" |
	"Postflight" |
	"Commit" |
	"Rollback" |
	"ClassifyError"

#TransactionAdapterMethod: close({
	name:        #AdapterMethodName
	goSignature: string & !=""
	input: [string & !="", ...(string & !="")]
	output: [string & !="", ...(string & !="")]
	from: [#TransactionState, ...#TransactionState]
	to: [#TransactionState, ...#TransactionState]
	journaled:         bool
	classifiesFailure: bool
})

#TransactionAdapterInterface: close({
	id:      "vcs.Transaction"
	backend: "go-git"

	contract: "#Transaction"
	methods: [#TransactionAdapterMethod, ...#TransactionAdapterMethod]

	unguardedStackMutatorsExposed: false
	errorClassification: close({
		failureClass:  "#FailureClass"
		rollbackClass: "#RollbackClass"
		recovery:      "#RecoveryReport"
	})
})

transactionAdapter: #TransactionAdapterInterface & {
	methods: [
		{
			name:        "ID"
			goSignature: "ID() string"
			input: ["Transaction"]
			output: ["string"]
			from: ["planned", "preflighted", "snapshot_created", "journal_opened", "mutation_started", "mutation_applied", "postflight_started", "committed", "rollback_started", "rolled_back", "rollback_partial", "rollback_failed", "aborted"]
			to: ["planned", "preflighted", "snapshot_created", "journal_opened", "mutation_started", "mutation_applied", "postflight_started", "committed", "rollback_started", "rolled_back", "rollback_partial", "rollback_failed", "aborted"]
			journaled:         false
			classifiesFailure: false
		},
		{
			name:        "State"
			goSignature: "State() TransactionState"
			input: ["Transaction"]
			output: ["TransactionState"]
			from: ["planned", "preflighted", "snapshot_created", "journal_opened", "mutation_started", "mutation_applied", "postflight_started", "committed", "rollback_started", "rolled_back", "rollback_partial", "rollback_failed", "aborted"]
			to: ["planned", "preflighted", "snapshot_created", "journal_opened", "mutation_started", "mutation_applied", "postflight_started", "committed", "rollback_started", "rolled_back", "rollback_partial", "rollback_failed", "aborted"]
			journaled:         false
			classifiesFailure: false
		},
		{
			name:        "Open"
			goSignature: "Open(ctx context.Context, command Command) (Transaction, error)"
			input: ["context.Context", "Command"]
			output: ["Transaction", "error"]
			from: ["planned"]
			to: ["planned"]
			journaled:         false
			classifiesFailure: true
		},
		{
			name:        "Preflight"
			goSignature: "Preflight(ctx context.Context) error"
			input: ["context.Context"]
			output: ["error"]
			from: ["planned"]
			to: ["preflighted", "aborted"]
			journaled:         false
			classifiesFailure: true
		},
		{
			name:        "Snapshot"
			goSignature: "Snapshot(ctx context.Context) (Snapshot, error)"
			input: ["context.Context"]
			output: ["Snapshot", "error"]
			from: ["preflighted"]
			to: ["snapshot_created", "aborted"]
			journaled:         false
			classifiesFailure: true
		},
		{
			name:        "Journal"
			goSignature: "Journal(ctx context.Context, entry JournalEntry) error"
			input: ["context.Context", "JournalEntry"]
			output: ["error"]
			from: ["snapshot_created", "journal_opened", "mutation_started", "mutation_applied", "postflight_started", "rollback_started"]
			to: ["journal_opened", "mutation_started", "mutation_applied", "postflight_started", "rollback_started"]
			journaled:         true
			classifiesFailure: true
		},
		{
			name:        "Apply"
			goSignature: "Apply(ctx context.Context, mutation Mutation) error"
			input: ["context.Context", "Mutation"]
			output: ["error"]
			from: ["journal_opened"]
			to: ["mutation_started", "mutation_applied", "rollback_started"]
			journaled:         true
			classifiesFailure: true
		},
		{
			name:        "Postflight"
			goSignature: "Postflight(ctx context.Context, validator Validator) error"
			input: ["context.Context", "Validator"]
			output: ["error"]
			from: ["mutation_applied"]
			to: ["postflight_started", "rollback_started"]
			journaled:         true
			classifiesFailure: true
		},
		{
			name:        "Commit"
			goSignature: "Commit(ctx context.Context) error"
			input: ["context.Context"]
			output: ["error"]
			from: ["postflight_started"]
			to: ["committed", "rollback_started"]
			journaled:         true
			classifiesFailure: true
		},
		{
			name:        "Rollback"
			goSignature: "Rollback(ctx context.Context, failure error) (*RecoveryReport, error)"
			input: ["context.Context", "error"]
			output: ["*RecoveryReport", "error"]
			from: ["mutation_started", "mutation_applied", "postflight_started", "rollback_started"]
			to: ["rollback_started", "rolled_back", "rollback_partial", "rollback_failed"]
			journaled:         true
			classifiesFailure: true
		},
		{
			name:        "ClassifyError"
			goSignature: "ClassifyError(err error, snapshot Snapshot) (FailureClass, RollbackClass)"
			input: ["error", "Snapshot"]
			output: ["FailureClass", "RollbackClass"]
			from: ["planned", "preflighted", "snapshot_created", "journal_opened", "mutation_started", "mutation_applied", "postflight_started", "rollback_started"]
			to: ["aborted", "rollback_started", "rollback_failed"]
			journaled:         false
			classifiesFailure: true
		},
	]
}
