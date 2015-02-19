//
//  Promise.swift
//  promises
//
//  Created by Rob Ringham on 6/7/14.
//  Copyright (c) 2014, Rob Ringham
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

internal enum Status{
    case Pending
    case Fulfilled
    case Rejected
}

public class Promise<T:Any> {
    private var _status:Status = .Pending
    private var _result:T? = nil
    private var _error: String = ""
    
    private var _thens: [((result:T?) -> ())] = []
    private var _fails: [(error:String) -> Void] = []
    
    // Resolve method.
    //
    // Returns a resolve function that loops through pending callbacks,
    // invoking each in sequence.
    //
    // Invokes fail callback in case of rejection (and swiftly abandons ship).
    public func resolve(result:T? = nil) -> Void {
        assert(_status == .Pending, "Promise has already been settled.")
        
        _result = result
        
        for then in _thens {
            if(_status == .Rejected){break} //EXPL: If it's rejected, halt callbacks.
            
            then(result:result?)
        }
        
        _status = .Fulfilled
    }
    
    // Reject method.
    //
    // Sets rejection flag to true to halt execution of subsequent callbacks.
    public func reject(error:String) -> () {
        assert(_status == .Pending, "Promise has already been settled.")
        
        _status = .Rejected
        _error = error
        
        for fail in _fails {
            fail(error:_error)
        }
    }
    
    // Then method.
    //
    // This lets us chain callbacks together; it accepts one parameter, a Void -> Void
    // callback - can either be a function itself, or a Swift closure.
    public func then(callback: ((T?) -> Void)) -> Promise {
        _thens.append(callback)
        
        if(_status == .Fulfilled){
            //EXPL: call any thens set *after* the promise is resolved.
            callback(_result)
        }
        
        return self
    }
    
    // Fail method.
    //
    // This lets us chain fail() methods
    public func fail(fail: (error:String) -> Void) -> Promise {
        _fails.append(fail)
        
        //EXPL: if the promise has already failed, make the call anyway.
        if(_status == .Rejected){
            fail(error:_error)
        }
        
        return self
    }
    
    public func map<R:Any>(mapFunction:(T?) -> (R?)) -> Promise<R>{
        var mappedPromise:Promise<R> = Promise<R>()
        
        self.then { (result) -> Void in
            let mappedResult = mapFunction(result)
            
            mappedPromise.resolve(result: mappedResult)
        }.fail { (error) -> Void in
            mappedPromise.reject(error)
        }
        
        return mappedPromise
    }
}