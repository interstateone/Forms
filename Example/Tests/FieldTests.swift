import Quick
import Nimble
@testable import Forms

class FieldSpec: QuickSpec {
    override func spec() {
        enum Id: String { case subject }
        var subject: Field<String>!

        beforeEach {
            subject = Field(Id.subject, name: "subject", value: "")
        }

        describe("validation") {
            var onValidateInvocationCount = 0
            beforeEach {
                onValidateInvocationCount = 0
                subject.onValidate = { _ in
                    onValidateInvocationCount += 1
                }
            }

            context("validates when blurred") {
                beforeEach {
                    subject.validatesWhen = .blurred
                }

                context("when the field is focussed") {
                    beforeEach {
                        subject.handleEvent(.focus)
                    }

                    context("when it is blurred") {
                        beforeEach {
                            subject.handleEvent(.blur)
                        }

                        it("is now untouched") {
                            expect(subject.state) == Field.State.untouched
                        }
                        it("validates") {
                            expect(onValidateInvocationCount) == 1
                        }
                    }
                }
                context("when the field is changed") {
                    beforeEach {
                        subject.handleEvent(.focus)
                        subject.handleEvent(.change)
                    }

                    context("when it is blurred") {
                        beforeEach {
                            subject.handleEvent(.blur)
                        }

                        it("is now blurred") {
                            expect(subject.state) == Field.State.blurred
                        }
                        it("validates") {
                            expect(onValidateInvocationCount) == 1
                        }
                    }
                }
            }

            context("validates when changed") {
                beforeEach {
                    subject.validatesWhen = .changed
                }

                context("when the field is untouched") {
                    beforeEach {
                        // .untouched is the initial state
                    }

                    context("when it is changed") {
                        beforeEach {
                            subject.handleEvent(.change)
                        }

                        it("is now blurred") {
                            expect(subject.state) == Field.State.blurred
                        }
                        it("validates") {
                            expect(onValidateInvocationCount) == 1
                        }
                    }
                }
                context("when the field is focused") {
                    beforeEach {
                        subject.handleEvent(.focus)
                    }

                    context("when it is changed") {
                        beforeEach {
                            subject.handleEvent(.change)
                        }

                        it("is now blurred") {
                            expect(subject.state) == Field.State.changed
                        }
                        it("validates") {
                            expect(onValidateInvocationCount) == 1
                        }
                    }
                }
                context("when the field is changed") {
                    beforeEach {
                        subject.handleEvent(.focus)
                        subject.handleEvent(.change)
                    }

                    context("when it is changed") {
                        beforeEach {
                            subject.handleEvent(.change)
                        }

                        it("is now changed") {
                            expect(subject.state) == Field.State.changed
                        }
                        it("validates") {
                            expect(onValidateInvocationCount) == 2
                        }
                    }
                }
                context("when the field is blurred") {
                    beforeEach {
                        subject.handleEvent(.focus)
                        subject.handleEvent(.change)
                        subject.handleEvent(.blur)
                    }

                    context("when it is changed") {
                        beforeEach {
                            subject.handleEvent(.change)
                        }

                        it("is now blurred") {
                            expect(subject.state) == Field.State.blurred
                        }
                        it("validates") {
                            expect(onValidateInvocationCount) == 2
                        }
                    }
                }

                describe("when changing the value") {
                    beforeEach {
                        subject.value = "a new value"
                    }

                    it("is now blurred") {
                        expect(subject.state) == Field.State.blurred
                    }
                    it("validates") {
                        expect(onValidateInvocationCount) == 1
                    }
                }
            }
        }
    }
}
