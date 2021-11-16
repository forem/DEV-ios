import SwiftUI
import UIKit

struct NewsModalView: View {
    @Environment(\.presentationMode) var presentationMode
    
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color.gray)
                        .opacity(0.75)
                        .font(.system(size: 25, weight: .bold))
                }
            }
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
            Text("DEV is available in Forem App")
                .font(Font.system(.title, design: .default).weight(.heavy))
                .padding(.horizontal)
                .multilineTextAlignment(.center)
            Text("You can download the Forem app from the App Store. Don’t worry about your profile information: it will be transferred to the Forem app.")
                .padding(.all)
                .padding(.top, 0)
                .multilineTextAlignment(.center)
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "arrow.down")
                Text("Download Forem App")
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
        NewsModalView()
    }
}
