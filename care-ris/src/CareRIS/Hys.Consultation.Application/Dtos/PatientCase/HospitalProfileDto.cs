﻿using System;

namespace Hys.Consultation.Application.Dtos
{
    public class HospitalProfileDto
    {
        public string UniqueID { get; set; }

        public string HospitalName { get; set; }

        public string Province { get; set; }
        public string City { get; set; }
        public string Area { get; set; }
        public string Address { get; set; }
        public string TelePhone { get; set; }
        public string Website { get; set; }
        public string Introduction { get; set; }
        public string HospitalType { get; set; }
        public string HospitalLevel { get; set; }
        public string DicomPrefix { get; set; }
        public string HospitalImage { get; set; }
        public string LastEditUser { get; set; }
        public bool? IsConsultation { get; set; }
        public bool Status { get; set; }
        public string Dam1ID { get; set; }
        public DAMInfoDto Dam1 { get; set; }
        public DateTime LastEditTime { get; set; }
    }
}