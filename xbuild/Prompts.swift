import Foundation
import Noora

struct Prompts {
    static func run(projectInfo: ProjectInfo, simulators: [Simulator], existingIdentifier: String? = nil) -> Config {
        let noora = Noora()

        let scheme: String = noora.singleChoicePrompt(
            title: "Scheme",
            question: "Which scheme do you want to build?",
            options: projectInfo.schemes,
            filterMode: projectInfo.schemes.count > 5 ? .enabled : .disabled
        )

        let configuration: String = noora.singleChoicePrompt(
            title: "Configuration",
            question: "Which configuration?",
            options: projectInfo.configurations
        )

        let simulator: Simulator = noora.singleChoicePrompt(
            title: "Destination",
            question: "Which simulator?",
            options: simulators,
            filterMode: simulators.count > 5 ? .enabled : .disabled
        )

        return Config.create(
            projectPath: projectInfo.path,
            scheme: scheme,
            configuration: configuration,
            destinationId: simulator.udid,
            existingIdentifier: existingIdentifier
        )
    }
}
