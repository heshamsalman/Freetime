//
//  GithubClient+Issues.swift
//  Freetime
//
//  Created by Ryan Nystrom on 6/2/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import UIKit
import IGListKit

extension GithubClient {

    func fetch(
        owner: String,
        repo: String,
        number: Int,
        width: CGFloat,
        completion: @escaping (String?, [ListDiffable]) -> ()
        ) {

        let query = IssueOrPullRequestQuery(owner: owner, repo: repo, number: number, pageSize: 100)
        apollo.fetch(query: query, cachePolicy: .fetchIgnoringCacheData) { (result, error) in
            let issueOrPullRequest = result?.data?.repository?.issueOrPullRequest
            if let issueType: IssueType = issueOrPullRequest?.asIssue ?? issueOrPullRequest?.asPullRequest {
                DispatchQueue.global().async {
                    let result = createViewModels(issue: issueType, width: width)
                    DispatchQueue.main.async {
                        completion(issueType.id, result)
                    }
                }
            } else {
                completion(nil, [])
            }
            ShowErrorStatusBar(graphQLErrors: result?.errors, networkError: error)
        }
    }

    func react(
        subjectID: String,
        content: ReactionContent,
        isAdd: Bool,
        completion: @escaping (IssueCommentReactionViewModel?) -> ()
        ) {
        if isAdd {
            apollo.perform(mutation: AddReactionMutation(subjectId: subjectID, content: content)) { (result, error) in
                if let reactionFields = result?.data?.addReaction?.subject.fragments.reactionFields {
                    completion(createIssueReactions(reactions: reactionFields))
                } else {
                    completion(nil)
                }
                ShowErrorStatusBar(graphQLErrors: result?.errors, networkError: error)
            }
        } else {
            apollo.perform(mutation: RemoveReactionMutation(subjectId: subjectID, content: content)) { (result, error) in
                if let reactionFields = result?.data?.removeReaction?.subject.fragments.reactionFields {
                    completion(createIssueReactions(reactions: reactionFields))
                } else {
                    completion(nil)
                }
                ShowErrorStatusBar(graphQLErrors: result?.errors, networkError: error)
            }
        }
    }

}
