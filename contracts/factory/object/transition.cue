package object

#Transition: close({
	id:     #TransitionID
	schema: "factory.transition.v1"
	feedback: #Feedback & {decision: "admit"}
	admitted: true
	binds: close({
		semantic:  #CandidateID
		runtime?:  #ObjectID
		material?: #ObjectID
	})
})

#GateResult: close({
	id:     #ObjectID
	schema: "factory.gate-result.v1"
	evaluation: #Evaluation & {passed: true}
	feedback?:   #Feedback
	transition?: #Transition
	admitted:    bool

	if admitted {
		feedback: #Feedback & {
			evaluation: evaluation
			decision:   "admit"
		}
		transition: #Transition & {
			feedback: feedback
			admitted: true
		}
	}
})

#Materialization: close({
	id:     #MaterializationID
	schema: "factory.materialization.v1"
	transition: #Transition & {admitted: true}
	workerID: #WorkerID
	surface:  #TransitionSurface
	summary:  #BoundedSummary
})
