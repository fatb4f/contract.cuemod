package object

#FixtureVerdict: close({
	schema:    "factory.fixture-verdict.v1"
	fixtureID: #NegativeFixtureID
	verdict:   #Verdict
	evidence: [...#EvidenceID] & [_, ...]
	reason: #BoundedSummary
})
