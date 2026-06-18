package object

#Feedback: close({
	id:     #FeedbackID
	schema: "factory.feedback.v1"
	evaluation: #Evaluation & {passed: true}
	decision: #Decision
	reason:   #BoundedSummary
})
