    //
//  NGPOD.swift
//  NGPOD
//
//  Created by Kenrick Vaz on 10/10/20.
//

import WidgetKit
import SwiftUI
import Intents
import Alamofire
import SwiftyJSON
import Kingfisher

struct Provider: IntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationIntent(), photo: UIImage(named: "widgetDefault")!, title: "Tiger")
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), configuration: configuration, photo: UIImage(named: "widgetDefault")!, title: "Tiger")
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        let currentDate = Date()
        let refreshDate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        
        PhotoLoader.fetch { result in
            let commit: SimpleEntry
            if case .success(let fetchedCommit) = result {
                commit = fetchedCommit
            } else {
                commit = SimpleEntry(date: Date(), configuration: ConfigurationIntent(), photo: UIImage(named: "widgetDefault")!, title: "Tiger")
            }
            let timeline = Timeline(entries: [commit], policy: .after(refreshDate))
            completion(timeline)
        }
        
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
    let photo: UIImage
    let title: String
}

    struct NGPODEntryView : SwiftUI.View {
    var entry: Provider.Entry

    var body: some SwiftUI.View {
        ZStack(alignment: .bottom) {
            Image(uiImage: entry.photo).resizable()
                .scaledToFill()
            VStack (alignment: .center) {
                Text(entry.title)
                    .font(.body)
                    .foregroundColor(.white)
                    .padding(20)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
                    
            }
            .frame(minWidth: 0,
                            maxWidth: .infinity,
                            minHeight: 0,
                            maxHeight: 30,
                            alignment: .center
                    )
            .padding(5)
            .background(Color.black.opacity(/*@START_MENU_TOKEN@*/0.8/*@END_MENU_TOKEN@*/))
        }
        
                    
    }
}

@main
struct NGPOD: Widget {
    let kind: String = "NGPOD"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            NGPODEntryView(entry: entry)
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
    }
}

struct NGPOD_Previews: PreviewProvider {
    static var previews: some SwiftUI.View {
        NGPODEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent(), photo: UIImage(named: "widgetDefault")!, title: "Tiger"))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}

    struct PhotoLoader {
        
        static func getCacheValue(_ key: String) -> String {
            let userdefaults = UserDefaults.standard
            return userdefaults.string(forKey: key) ?? ""
        }

        static func setCacheValue(_ key: String, value: String) {
            let userdefaults = UserDefaults.standard
            userdefaults.set(value, forKey: key)
        }
        
        static func getCurrentDate() -> String {
            let date = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "dd.MM.yyyy"
            return formatter.string(from: date)
        }
        
        static func fetch(completion: @escaping (Result<SimpleEntry, Error>) -> Void) {
            
            /*
            let currentDate = getCurrentDate()
            
           
            //check cache first
            if(getCacheValue("currentDate") == currentDate) {
                
                downloadImage(getCacheValue("ngpodImage"), completion: completion)
            }
            */
            AF.request("https://ngpod-api.herokuapp.com/api/photo")
                .responseJSON { (response) in
                    
                    let pod = JSON(response.data!)
              
                    if(pod["title"].string == "") {
                        print("SOMETHING IS NOT RIGHT!")
                        completion(.success(SimpleEntry(date: Date(), configuration: ConfigurationIntent(), photo: UIImage(named: "widgetDefault")!, title: "Tiger")))
                        
                    } else {
                        
                        downloadImage(pod["image"].string!, title: pod["title"].string!, completion: completion)
                        
                    }
                }
        }
        
        static func downloadImage(_ imageUrl: String, title: String, completion: @escaping (Result<SimpleEntry, Error>) -> Void) {
            let url = URL(string: imageUrl)
            
            let downloader = ImageDownloader.default
            downloader.downloadImage(with: url!) { result in
                switch result {
                case .success(let value):
                    print(value.image)
                    setCacheValue("currentDate", value: getCurrentDate())
                    setCacheValue("ngpodImage", value: imageUrl)
                    
                    completion(.success(SimpleEntry(date: Date(), configuration: ConfigurationIntent(), photo: value.image, title: title)))
                case .failure(let error):
                    print(error)
                    completion(.success(SimpleEntry(date: Date(), configuration: ConfigurationIntent(), photo: UIImage(named: "widgetDefault")!, title: "Tiger")))
                }
            }
        }
    }

    
    
    
