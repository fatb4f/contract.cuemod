package transition

import object "github.com/fatb4f/contract.reflective-transition-factory/contracts/factory/object"

#NoCandidateWithoutNegativeFixture: {
	candidate: object.#Candidate
}

#NoPassingEvaluationWithoutFixtureVerdicts: {
	evaluation: object.#Evaluation & {passed: true}
}

#NoAdmittedFeedbackUnlessEvaluationPasses: {
	feedback: object.#Feedback
	feedback: {
		evaluation: {
			passed: true
		}
	}
}

#NoTransitionUnlessFeedbackAdmits: {
	transition: object.#Transition
	transition: {
		feedback: {
			decision: "admit"
		}
		admitted: true
	}
}

#NoMaterializationBeforeAdmittedTransition: {
	materialization: object.#Materialization
	materialization: {
		transition: {
			admitted: true
		}
	}
}

#NoRawAuthorityExposure: {
	candidate:  object.#Candidate
	evaluation: object.#Evaluation
	transition: object.#Transition
}

#DeterministicGateInvariants: close({
	candidate: object.#Candidate
	evaluation: object.#Evaluation & {
		candidate: candidate
	}
	feedback: object.#Feedback & {
		evaluation: evaluation
	}
	transition: object.#Transition & {
		feedback: feedback
	}
	materialization: object.#Materialization & {
		transition: transition
	}

	#NoCandidateWithoutNegativeFixture & {
		candidate: candidate
	}
	#NoPassingEvaluationWithoutFixtureVerdicts & {
		evaluation: evaluation
	}

	#NoAdmittedFeedbackUnlessEvaluationPasses & {
		feedback: feedback
	}

	#NoTransitionUnlessFeedbackAdmits & {
		transition: transition
	}

	#NoMaterializationBeforeAdmittedTransition & {
		materialization: materialization
	}
})
