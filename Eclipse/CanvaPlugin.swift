//
//  CanvaPlugin.swift
//  Eclipse
//
//  Created by Antigravity on 12/18/25.
//

import Foundation
import UIKit

class CanvaPlugin: AppPlugin {
    var appId: String = "canva"
    
    var systemPromptExtension: String {
        """
        You are now connected to the Canva Plugin. You can help users create beautiful designs, flyers, social media posts, and more.

        ## CAPABILITIES:
        - Generate design ideas and create actual Canva templates for users to edit
        - Create flyers, presentations, social media posts, and banners

        ## HOW TO CREATE A DESIGN:
        When a user asks to create a design (e.g., "create a flyer for a car wash" or "make a birthday card"), you should:
        1.  Analyze their request to identify the *type* of design (flyer, post, presentation) and the *subject*.
        2.  Generate 3-5 distinct titles for potential designs.
        3.  Format your response using this EXACT structure:

        [CANVA_DESIGN:TemplateType|Title 1,Title 2,Title 3]

        ## CRITICAL RULES:
        - The CANVA_DESIGN tag must be on its own line
        - **TemplateType** must be one of: `presentation`, `infographic`, `poster`, `doc`, `whiteboard`. (Default to `presentation` if unsure or for general usage like flyers, as it's the most versatile canvas).
        - Use the pipe symbol (|) to separate the template type from the titles.
        - Use commas to separate individual design titles.
        - Provide at least 3 options so the user has choices.
        - After the tag, add a friendly confirmation like "I've started these designs for you. Tap one to open it in Canva!"

        ## EXAMPLE RESPONSE:
        [CANVA_DESIGN:presentation|Premium Car Wash Flyer,Blue Water Splash Promo,Modern Auto Detailing Service]

        I've created a few flyer concepts for your car wash. You can tap any of them to start editing in Canva!
        """
    }
    
    func handleToolCall(name: String, arguments: [String : Any]) async throws -> String? {
        // This will be called when the AI uses the CANVA_CREATE command
        return nil
    }
}
