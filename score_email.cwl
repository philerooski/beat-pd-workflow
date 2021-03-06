#!/usr/bin/env cwl-runner
#
# Example score emails to participants
#
cwlVersion: v1.0
class: CommandLineTool
baseCommand: python3

hints:
  DockerRequirement:
    dockerPull: sagebionetworks/synapsepythonclient:v1.9.4

inputs:
  - id: submissionid
    type: int
  - id: synapse_config
    type: File
  - id: results
    type: File
  - id: private_annotations
    type: string[]?

arguments:
  - valueFrom: score_email.py
  - valueFrom: $(inputs.submissionid)
    prefix: -s
  - valueFrom: $(inputs.synapse_config.path)
    prefix: -c
  - valueFrom: $(inputs.results)
    prefix: -r
  - valueFrom: $(inputs.private_annotations)
    prefix: -p


requirements:
  - class: InlineJavascriptRequirement
  - class: InitialWorkDirRequirement
    listing:
      - entryname: score_email.py
        entry: |
          #!/usr/bin/env python
          import synapseclient
          import argparse
          import json
          import os
          parser = argparse.ArgumentParser()
          parser.add_argument("-s", "--submissionid", required=True, help="Submission ID")
          parser.add_argument("-c", "--synapse_config", required=True, help="credentials file")
          parser.add_argument("-r", "--results", required=True, help="Resulting scores")
          parser.add_argument("-p", "--private_annotaions", nargs="+",
                              default=[], help="annotations to not be sent via e-mail")
          args = parser.parse_args()
          syn = synapseclient.Synapse(configPath=args.synapse_config)
          syn.login()

          sub = syn.getSubmission(args.submissionid)
          userid = sub.userId
          evaluation = syn.getEvaluation(sub.evaluationId)
          with open(args.results) as json_data:
            annots = json.load(json_data)
          if annots.get("validation_and_scoring_error") is None:
            raise Exception("score.cwl must return `validation_and_scoring_error` as a json key")
          for annot in args.private_annotaions:
            del annots[annot]
          if not annots["validation_and_scoring_error"]:
            del annots["validation_and_scoring_error"]
            # We do not report score to participant
            #
            #subject = "Submission to '%s' scored!" % evaluation.name
            #message = ["Hello %s,\n\n" % syn.getUserProfile(userid)['userName'],
            #           "Your submission (%s) is scored, below are your results:\n\n" % sub.name,
            #           "\n".join([i + " : " + str(annots[i]) for i in annots]),
            #           "\n\nSincerely,\nBEAT-PD Challenge Administrator"]
            subject = "Submission to {} is valid!".format(evaluation.name)
            message = ["Hello %s,\n\n" % syn.getUserProfile(userid)['userName'],
                       "Your submission (%s) is valid and has been scored.\n\n" % sub.name,
                       "At the end of the current round, you will receive an email "
                       "containing the model rank, and whether the model performed "
                       "better than the null model. In the event that you submit "
                       "additional models before the round deadline, you will only "
                       "receive this information for the last valid model submitted "
                       "prior to the deadline."
                       "\n\nSincerely,\nThe BEAT-PD Challenge Administrator"]
          else:
            subject = "Submission to '%s' is invalid" % evaluation.name
            if "problems" in annots: # we had trouble reading the input as csv
                message = ["Hello %s,\n\n" % syn.getUserProfile(userid)['userName'],
                           "We were unable to read your submission (%s) as a CSV file.\n\n" % sub.name,
                           "Below is a JSON summary of the parsing issues we encountered:\n\n",
                           json.dumps(annots["problems"], indent=2),
                           "\n\nSincerely,\nBEAT-PD Challenge Administrator"]
            else: # some other issue
                message = ["Hello %s,\n\n" % syn.getUserProfile(userid)['userName'],
                           "We encountered the following problem with your submission (%s)\n\n" % sub.name,
                           annots["message"],
                           "\n\nSincerely,\nThe BEAT-PD Challenge Administrator"]
          syn.sendMessage(
              userIds=[userid],
              messageSubject=subject,
              messageBody="".join(message),
              contentType="text")

          
outputs: []
