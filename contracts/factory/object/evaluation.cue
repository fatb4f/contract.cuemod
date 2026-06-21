package object

import "list"

#Evaluation: close({
	id:        #EvaluationID
	schema:    "factory.evaluation.v1"
	candidate: #Candidate
	verdicts: [...#FixtureVerdict] & [_, ...]
	assertions: [...#AssertionResult]
	passed: bool
	fixtureVerdictsCovered: [...true] & [
		for fixtureID in candidate.fixtures {
			list.Contains([for verdict in verdicts {verdict.fixtureID}], fixtureID)
		},
	]

	if passed {
		verdicts: [...#FixtureVerdict & {verdict: "negated"}] & [_, ...]
	}
})
