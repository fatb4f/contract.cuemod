package object

#AssertionResult: close({
	id:      #ObjectID
	schema:  "factory.assertion-result.v1"
	name:    string & !=""
	passed:  bool
	subject: #ObjectID
	reason?: #BoundedSummary
})
