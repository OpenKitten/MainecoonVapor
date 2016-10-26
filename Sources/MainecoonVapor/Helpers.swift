@_exported import Mainecoon
import BSON
import Vapor
import HTTP

extension ObjectId: StringInitializable {
    public init?(from string: String) throws {
        self = try ObjectId(string)
    }
}

extension Document : ResponseRepresentable, RequestInitializable {
    public func makeResponse() throws -> Response {
        return Response(status: .ok, headers: ["Content-Type": "application/json"], body: self.makeExtendedJSON())
    }
    
    public init(request: Request) throws {
        let bytes = request.body.bytes ?? []
        let json = try String(bytes: bytes)
        
        try self.init(extendedJSON: json)
    }
}

extension HTTP.Response {
    public convenience init(status: HTTP.Status, document: Document) {
        self.init(status: status, headers: ["Content-Type": "application/json"], body: document.makeExtendedJSON())
    }
}

open class VaporInstance: BasicInstance, ResponseRepresentable, RequestInitializable {
    /// Defaults to all
    public var defaultApiFields: [String]? = nil
    
    public var apiResponse: Document {
        guard let defaultApiFields = defaultApiFields else {
            return self.document
        }
        
        var response: Document = [:]
        
        for field in defaultApiFields {
            response[field] = self.getProperty(field)
        }
        
        return response
    }
    
    public required init(request: Request) throws {
        let document = try Document(request: request)
        
        try super.init(document)
    }
    
    public required init(_ document: Document, validatingDocument validate: Bool) throws {
        try super.init(document, validatingDocument: validate)
    }
    
    public required init(_ document: Document, projectedBy projection: Projection, validatingDocument validate: Bool) throws {
        try super.init(document, projectedBy: projection, validatingDocument: validate)
    }
    
    public func makeResponse() throws -> Response {
        return try self.apiResponse.makeResponse()
    }
    
    public func makeResponse(withFields fields: [String]) throws -> Response {
        var response: Document = [:]
        
        for field in fields {
            response[field] = self.getProperty(field)
        }
        
        return try response.makeResponse()
    }
}