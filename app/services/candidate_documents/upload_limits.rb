module CandidateDocuments
  module UploadLimits
    def self.max_size_bytes
      ENV.fetch("MAX_CV_SIZE_MB", "25").to_i.megabytes
    end
  end
end
