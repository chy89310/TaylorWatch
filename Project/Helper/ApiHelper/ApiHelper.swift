//
//  ApiHelper.swift
//  Project
//
//  Created by Kevin Sum on 9/7/2017.
//  Copyright © 2017 Kevin Sum. All rights reserved.
//

import Alamofire
import Foundation
import MagicalRecord
import SwiftyJSON

class ApiHelper: NSObject {
    
    // Mark: - Properties
    
    static let shared = ApiHelper()
    
    override init() {
        super.init()
        updateDataFromPlist()
    }
    
    // MARK: - Public methods
    
    func request(
        name: ApiHelper.Name,
        env: ApiHelper.Env = defaultEnv,
        method: Alamofire.HTTPMethod = .get,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding = URLEncoding.default,
        headers: HTTPHeaders? = nil,
        urlUpdate: (URL) -> (URL) = { (url) in return url },
        success: ((JSON, DataResponse<Any>) -> ())?,
        failure: ((Error, DataResponse<Any>) -> ())?) {
        if let url = url(forName: name) {
            Alamofire.request(
                urlUpdate(url),
                method: method,
                parameters: parameters,
                encoding: encoding,
                headers: headers)
                .responseJSON { (response) in
                    switch response.result {
                    case .success(let value):
                        success?(JSON(value), response)
                    case .failure(let error):
                        log.error("Api request failure: \(error)")
                        failure?(error, response)
                    }
            }
        }
    }
    
    func url(forName name: ApiHelper.Name, env: ApiHelper.Env = defaultEnv) -> URL? {
        if let baseUrl = value(forName: .baseUrl, env: env) {
            if let url = URL(string: value(forName: name, env: env) ?? "", relativeTo: URL(string: baseUrl)) {
                return url
            } else {
                log.warning("ApiHelper can not return the url properly with name(\(name)), env(\(env))")
                return nil
            }
        } else {
            log.error("ApiHelper can not get the baseUrl. Please make sure there is one string or dictionary record with key baseUrl in Api.plist!")
            return nil
        }
    }
    
    // MARK: - Private methods
    
    private func updateDataFromPlist() {
        let json = Helper.readPlist("Api")
        // Do the data operation in default context
        MagicalRecord.save(blockAndWait: { (localContext) in
            // Always truncate the table first
            Api.mr_truncateAll(in: localContext)
            // Save entity block
            func saveEntity(name: String, env: String?, value: String?) {
                let api = Api.mr_createEntity(in: localContext)
                api?.name = name
                api?.env = env
                api?.value = value
            }
            // Parser
            for (name, valueJson) in json {
                if let string = valueJson.string, string != "" {
                    // A string value
                    saveEntity(name: name, env: ApiHelper.Env.prod.rawValue, value: string)
                } else if let dict = valueJson.dictionary {
                    // A dictionary with different env
                    var hasProd = false
                    for env in dict.keys {
                        if (env == ApiHelper.Env.prod.rawValue) { hasProd = true }
                        saveEntity(name: name, env: env, value: dict[env]?.stringValue)
                    }
                    if (!hasProd) {
                        assert(false, "prod is a required env")
                    }
                } else if let number = valueJson.number {
                    saveEntity(name: name, env: ApiHelper.Env.prod.rawValue, value: "\(number.doubleValue)")
                } else {
                    assert(false, "Api.plist parse error, please check the file or add your own handler here")
                }
            }
        })
    }
    
    private func value(forName name: ApiHelper.Name, env: ApiHelper.Env = defaultEnv) -> String? {
        let namePredicate = NSPredicate(format: "name == %@", name.rawValue)
        let envPredicate = NSPredicate(format: "env == %@", env.rawValue)
        if let value = Api.mr_findFirst(
            with: NSCompoundPredicate(andPredicateWithSubpredicates: [namePredicate, envPredicate]))?.value {
            // Try to get the value with specify name and env first
            return value
        } else {
            // Get the value only by name
            return Api.mr_findFirst(with: namePredicate)?.value
        }
    }
    
}
