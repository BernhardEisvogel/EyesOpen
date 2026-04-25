import Vision

func test() {
    let req = VNDetectFaceLandmarksRequest()
    req.revision = VNDetectFaceLandmarksRequestRevision3
    print("Revision set to 3")
}
test()
