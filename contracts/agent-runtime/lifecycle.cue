package agentruntime

#LifecycleState:
	"pending" |
	"running" |
	"completed" |
	"failed" |
	"blocked"

#LifecycleEvent: close({
	state:   #LifecycleState
	at:      string & !=""
	detail?: string & !=""
})

#ExecutionLifecycle: close({
	state: #LifecycleState
	history: [...#LifecycleEvent] & [_, ...]
	startedAt?:  string & !=""
	finishedAt?: string & !=""

	if state == "running" {
		startedAt: string
	}
	if state == "completed" || state == "failed" || state == "blocked" {
		startedAt:  string
		finishedAt: string
	}
})
