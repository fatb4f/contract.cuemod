package object

#ID: string & =~"^[a-z0-9][a-z0-9._/-]*$"

#ObjectID: #ID

#WorkerID: #ID

#RuntimeEventID: #ID

#ResolverSelectionID: #ID

#EvidenceRequestID: #ID

#EvidenceID: #ID

#NegativeFixtureID: #ID

#CandidateID: #ID

#EvaluationID: #ID

#FeedbackID: #ID

#TransitionID: #ID

#MaterializationID: #ID

#TransitionSurface:
	"semantic" |
	"runtime" |
	"material"

#WorkerKind:
	"cue" |
	"codex" |
	"gitbutler"

#Decision:
	"admit" |
	"reject" |
	"revise"

#Verdict:
	"negated" |
	"still-fails" |
	"not-applicable"

#BoundedSummary: string & !=""

#RawObservationKind:
	"raw-diff" |
	"raw-log" |
	"raw-sdk-internals" |
	"raw-git-topology" |
	"raw-codex-runtime-internals" |
	"raw-cue-output" |
	"full-repo-firehose"
