import SwiftUI
import UIKit

struct NewsModalView: View {
    var dismissAction: (() -> Void)
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: {
                    dismissAction()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color.gray)
                        .opacity(0.75)
                        .font(.system(size: 25, weight: .bold))
                }
            }
            .padding(.top, 10.0)
            Spacer()
            Image("ForemBot")
                .interpolation(.high)
                .renderingMode(.original)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipped()
                .mask(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(radius: 2)
                .padding()
            Text("Find DEV in the Forem app")
                .font(Font.system(.title, design: .default).weight(.heavy))
                .padding(.horizontal)
                .multilineTextAlignment(.center)
            Text("Get Forem for iOS in the App Store. Your DEV profile info will be carried over so you can pick up where you left off!")
                .multilineTextAlignment(.center)
                .padding(.bottom, 25)
                .padding(.top, 5)
                .padding(.horizontal)
            Button(action: {
                UIApplication.shared.open(URL(string: "https://apps.apple.com/us/app/forem/id1536933197")!)
                dismissAction()
            }) {
                HStack {
                    Image(systemName: "arrow.down")
                    Text("Download Forem App")
                }
            }
            .background(Group {
                EmptyView()
            }, alignment: .center)
            .padding()
            .background(Color.blue)
            .foregroundColor(Color.white)
            .cornerRadius(14)
            .shadow(radius: 2)
            Spacer()
        }
        .clipped()
        .padding(.vertical, 10)
        .padding(.horizontal, 10)
    }
}

struct NewsModalView_Previews: PreviewProvider {
    static var previews: some View {
        NewsModalView(dismissAction: {})
    }
}
