﻿//------------------------------------------------------------------------------
// <auto-generated>
//     This code was generated by a tool.
//     Runtime Version:4.0.30319.18408
//
//     Changes to this file may cause incorrect behavior and will be lost if
//     the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------

// 
// This source code was auto-generated by Microsoft.VSDesigner, Version 4.0.30319.18408.
// 
#pragma warning disable 1591

namespace Hys.Platform.Domain.Ris
{
    using System;
    using System.Web.Services;
    using System.Diagnostics;
    using System.Web.Services.Protocols;
    using System.Xml.Serialization;
    using System.ComponentModel;


    /// <remarks/>
    [System.CodeDom.Compiler.GeneratedCodeAttribute("System.Web.Services", "4.0.30319.18408")]
    [System.Diagnostics.DebuggerStepThroughAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]
    [System.Web.Services.WebServiceBindingAttribute(Name = "SelfServiceReportSoap", Namespace = "http://tempuri.org/")]
    public partial class SelfServiceReport : System.Web.Services.Protocols.SoapHttpClientProtocol
    {

        private System.Threading.SendOrPostCallback HelloWorldOperationCompleted;

        private System.Threading.SendOrPostCallback GetPatientIDOperationCompleted;

        private System.Threading.SendOrPostCallback GetPatientInfoOperationCompleted;

        private System.Threading.SendOrPostCallback GetReportStatusOperationCompleted;

        private System.Threading.SendOrPostCallback GetPDFReportListOperationCompleted;

        private System.Threading.SendOrPostCallback GetPDFListtoPrintOperationCompleted;

        private System.Threading.SendOrPostCallback DownloadCompleteOperationCompleted;

        private bool useDefaultCredentialsSetExplicitly;

        /// <remarks/>
        public SelfServiceReport(string url)
        {
            this.Url = url;
            if ((this.IsLocalFileSystemWebService(this.Url) == true))
            {
                this.UseDefaultCredentials = true;
                this.useDefaultCredentialsSetExplicitly = false;
            }
            else
            {
                this.useDefaultCredentialsSetExplicitly = true;
            }
        }

        public new string Url
        {
            get
            {
                return base.Url;
            }
            set
            {
                if ((((this.IsLocalFileSystemWebService(base.Url) == true)
                            && (this.useDefaultCredentialsSetExplicitly == false))
                            && (this.IsLocalFileSystemWebService(value) == false)))
                {
                    base.UseDefaultCredentials = false;
                }
                base.Url = value;
            }
        }

        public new bool UseDefaultCredentials
        {
            get
            {
                return base.UseDefaultCredentials;
            }
            set
            {
                base.UseDefaultCredentials = value;
                this.useDefaultCredentialsSetExplicitly = true;
            }
        }

        /// <remarks/>
        public event HelloWorldCompletedEventHandler HelloWorldCompleted;

        /// <remarks/>
        public event GetPatientIDCompletedEventHandler GetPatientIDCompleted;

        /// <remarks/>
        public event GetPatientInfoCompletedEventHandler GetPatientInfoCompleted;

        /// <remarks/>
        public event GetReportStatusCompletedEventHandler GetReportStatusCompleted;

        /// <remarks/>
        public event GetPDFReportListCompletedEventHandler GetPDFReportListCompleted;

        /// <remarks/>
        public event GetPDFListtoPrintCompletedEventHandler GetPDFListtoPrintCompleted;

        /// <remarks/>
        public event DownloadCompleteCompletedEventHandler DownloadCompleteCompleted;

        /// <remarks/>
        [System.Web.Services.Protocols.SoapDocumentMethodAttribute("http://tempuri.org/HelloWorld", RequestNamespace = "http://tempuri.org/", ResponseNamespace = "http://tempuri.org/", Use = System.Web.Services.Description.SoapBindingUse.Literal, ParameterStyle = System.Web.Services.Protocols.SoapParameterStyle.Wrapped)]
        public string HelloWorld()
        {
            object[] results = this.Invoke("HelloWorld", new object[0]);
            return ((string)(results[0]));
        }

        /// <remarks/>
        public void HelloWorldAsync()
        {
            this.HelloWorldAsync(null);
        }

        /// <remarks/>
        public void HelloWorldAsync(object userState)
        {
            if ((this.HelloWorldOperationCompleted == null))
            {
                this.HelloWorldOperationCompleted = new System.Threading.SendOrPostCallback(this.OnHelloWorldOperationCompleted);
            }
            this.InvokeAsync("HelloWorld", new object[0], this.HelloWorldOperationCompleted, userState);
        }

        private void OnHelloWorldOperationCompleted(object arg)
        {
            if ((this.HelloWorldCompleted != null))
            {
                System.Web.Services.Protocols.InvokeCompletedEventArgs invokeArgs = ((System.Web.Services.Protocols.InvokeCompletedEventArgs)(arg));
                this.HelloWorldCompleted(this, new HelloWorldCompletedEventArgs(invokeArgs.Results, invokeArgs.Error, invokeArgs.Cancelled, invokeArgs.UserState));
            }
        }

        /// <remarks/>
        [System.Web.Services.Protocols.SoapDocumentMethodAttribute("http://tempuri.org/GetPatientID", RequestNamespace = "http://tempuri.org/", ResponseNamespace = "http://tempuri.org/", Use = System.Web.Services.Description.SoapBindingUse.Literal, ParameterStyle = System.Web.Services.Protocols.SoapParameterStyle.Wrapped)]
        public string GetPatientID(string card_number, string card_type)
        {
            object[] results = this.Invoke("GetPatientID", new object[] {
                        card_number,
                        card_type});
            return ((string)(results[0]));
        }

        /// <remarks/>
        public void GetPatientIDAsync(string card_number, string card_type)
        {
            this.GetPatientIDAsync(card_number, card_type, null);
        }

        /// <remarks/>
        public void GetPatientIDAsync(string card_number, string card_type, object userState)
        {
            if ((this.GetPatientIDOperationCompleted == null))
            {
                this.GetPatientIDOperationCompleted = new System.Threading.SendOrPostCallback(this.OnGetPatientIDOperationCompleted);
            }
            this.InvokeAsync("GetPatientID", new object[] {
                        card_number,
                        card_type}, this.GetPatientIDOperationCompleted, userState);
        }

        private void OnGetPatientIDOperationCompleted(object arg)
        {
            if ((this.GetPatientIDCompleted != null))
            {
                System.Web.Services.Protocols.InvokeCompletedEventArgs invokeArgs = ((System.Web.Services.Protocols.InvokeCompletedEventArgs)(arg));
                this.GetPatientIDCompleted(this, new GetPatientIDCompletedEventArgs(invokeArgs.Results, invokeArgs.Error, invokeArgs.Cancelled, invokeArgs.UserState));
            }
        }

        /// <remarks/>
        [System.Web.Services.Protocols.SoapDocumentMethodAttribute("http://tempuri.org/GetPatientInfo", RequestNamespace = "http://tempuri.org/", ResponseNamespace = "http://tempuri.org/", Use = System.Web.Services.Description.SoapBindingUse.Literal, ParameterStyle = System.Web.Services.Protocols.SoapParameterStyle.Wrapped)]
        public bool GetPatientInfo(string card_number, string card_type, out string strPatientID, out string strPatientName)
        {
            object[] results = this.Invoke("GetPatientInfo", new object[] {
                        card_number,
                        card_type});
            strPatientID = ((string)(results[1]));
            strPatientName = ((string)(results[2]));
            return ((bool)(results[0]));
        }

        /// <remarks/>
        public void GetPatientInfoAsync(string card_number, string card_type)
        {
            this.GetPatientInfoAsync(card_number, card_type, null);
        }

        /// <remarks/>
        public void GetPatientInfoAsync(string card_number, string card_type, object userState)
        {
            if ((this.GetPatientInfoOperationCompleted == null))
            {
                this.GetPatientInfoOperationCompleted = new System.Threading.SendOrPostCallback(this.OnGetPatientInfoOperationCompleted);
            }
            this.InvokeAsync("GetPatientInfo", new object[] {
                        card_number,
                        card_type}, this.GetPatientInfoOperationCompleted, userState);
        }

        private void OnGetPatientInfoOperationCompleted(object arg)
        {
            if ((this.GetPatientInfoCompleted != null))
            {
                System.Web.Services.Protocols.InvokeCompletedEventArgs invokeArgs = ((System.Web.Services.Protocols.InvokeCompletedEventArgs)(arg));
                this.GetPatientInfoCompleted(this, new GetPatientInfoCompletedEventArgs(invokeArgs.Results, invokeArgs.Error, invokeArgs.Cancelled, invokeArgs.UserState));
            }
        }

        /// <remarks/>
        [System.Web.Services.Protocols.SoapDocumentMethodAttribute("http://tempuri.org/GetReportStatus", RequestNamespace = "http://tempuri.org/", ResponseNamespace = "http://tempuri.org/", Use = System.Web.Services.Description.SoapBindingUse.Literal, ParameterStyle = System.Web.Services.Protocols.SoapParameterStyle.Wrapped)]
        public int GetReportStatus(string accession_number)
        {
            object[] results = this.Invoke("GetReportStatus", new object[] {
                        accession_number});
            return ((int)(results[0]));
        }

        /// <remarks/>
        public void GetReportStatusAsync(string accession_number)
        {
            this.GetReportStatusAsync(accession_number, null);
        }

        /// <remarks/>
        public void GetReportStatusAsync(string accession_number, object userState)
        {
            if ((this.GetReportStatusOperationCompleted == null))
            {
                this.GetReportStatusOperationCompleted = new System.Threading.SendOrPostCallback(this.OnGetReportStatusOperationCompleted);
            }
            this.InvokeAsync("GetReportStatus", new object[] {
                        accession_number}, this.GetReportStatusOperationCompleted, userState);
        }

        private void OnGetReportStatusOperationCompleted(object arg)
        {
            if ((this.GetReportStatusCompleted != null))
            {
                System.Web.Services.Protocols.InvokeCompletedEventArgs invokeArgs = ((System.Web.Services.Protocols.InvokeCompletedEventArgs)(arg));
                this.GetReportStatusCompleted(this, new GetReportStatusCompletedEventArgs(invokeArgs.Results, invokeArgs.Error, invokeArgs.Cancelled, invokeArgs.UserState));
            }
        }

        /// <remarks/>
        [System.Web.Services.Protocols.SoapDocumentMethodAttribute("http://tempuri.org/GetPDFReportList", RequestNamespace = "http://tempuri.org/", ResponseNamespace = "http://tempuri.org/", Use = System.Web.Services.Description.SoapBindingUse.Literal, ParameterStyle = System.Web.Services.Protocols.SoapParameterStyle.Wrapped)]
        [return: System.Xml.Serialization.XmlArrayAttribute("pdf_urls")]
        public string[] GetPDFReportList(string accession_number, string modality_type, string report_guid, int report_src, bool is_thirdparty)
        {
            object[] results = this.Invoke("GetPDFReportList", new object[] {
                        accession_number,
                        modality_type,
                        report_guid,
                        report_src,
                        is_thirdparty});
            return ((string[])(results[0]));
        }

        /// <remarks/>
        public void GetPDFReportListAsync(string accession_number, string modality_type, string report_guid, int report_src, bool is_thirdparty)
        {
            this.GetPDFReportListAsync(accession_number, modality_type, report_guid, report_src, is_thirdparty, null);
        }

        /// <remarks/>
        public void GetPDFReportListAsync(string accession_number, string modality_type, string report_guid, int report_src, bool is_thirdparty, object userState)
        {
            if ((this.GetPDFReportListOperationCompleted == null))
            {
                this.GetPDFReportListOperationCompleted = new System.Threading.SendOrPostCallback(this.OnGetPDFReportListOperationCompleted);
            }
            this.InvokeAsync("GetPDFReportList", new object[] {
                        accession_number,
                        modality_type,
                        report_guid,
                        report_src,
                        is_thirdparty}, this.GetPDFReportListOperationCompleted, userState);
        }

        private void OnGetPDFReportListOperationCompleted(object arg)
        {
            if ((this.GetPDFReportListCompleted != null))
            {
                System.Web.Services.Protocols.InvokeCompletedEventArgs invokeArgs = ((System.Web.Services.Protocols.InvokeCompletedEventArgs)(arg));
                this.GetPDFReportListCompleted(this, new GetPDFReportListCompletedEventArgs(invokeArgs.Results, invokeArgs.Error, invokeArgs.Cancelled, invokeArgs.UserState));
            }
        }

        /// <remarks/>
        [System.Web.Services.Protocols.SoapDocumentMethodAttribute("http://tempuri.org/GetPDFListtoPrint", RequestNamespace = "http://tempuri.org/", ResponseNamespace = "http://tempuri.org/", Use = System.Web.Services.Description.SoapBindingUse.Literal, ParameterStyle = System.Web.Services.Protocols.SoapParameterStyle.Wrapped)]
        [return: System.Xml.Serialization.XmlArrayAttribute("pdf_urls")]
        public string[] GetPDFListtoPrint(string accno, string modalityType, string templateType)
        {
            object[] results = this.Invoke("GetPDFListtoPrint", new object[] {
                        accno,
                        modalityType,
                        templateType});
            return ((string[])(results[0]));
        }

        /// <remarks/>
        public void GetPDFListtoPrintAsync(string accno, string modalityType, string templateType)
        {
            this.GetPDFListtoPrintAsync(accno, modalityType, templateType, null);
        }

        /// <remarks/>
        public void GetPDFListtoPrintAsync(string accno, string modalityType, string templateType, object userState)
        {
            if ((this.GetPDFListtoPrintOperationCompleted == null))
            {
                this.GetPDFListtoPrintOperationCompleted = new System.Threading.SendOrPostCallback(this.OnGetPDFListtoPrintOperationCompleted);
            }
            this.InvokeAsync("GetPDFListtoPrint", new object[] {
                        accno,
                        modalityType,
                        templateType}, this.GetPDFListtoPrintOperationCompleted, userState);
        }

        private void OnGetPDFListtoPrintOperationCompleted(object arg)
        {
            if ((this.GetPDFListtoPrintCompleted != null))
            {
                System.Web.Services.Protocols.InvokeCompletedEventArgs invokeArgs = ((System.Web.Services.Protocols.InvokeCompletedEventArgs)(arg));
                this.GetPDFListtoPrintCompleted(this, new GetPDFListtoPrintCompletedEventArgs(invokeArgs.Results, invokeArgs.Error, invokeArgs.Cancelled, invokeArgs.UserState));
            }
        }

        /// <remarks/>
        [System.Web.Services.Protocols.SoapDocumentMethodAttribute("http://tempuri.org/DownloadComplete", RequestNamespace = "http://tempuri.org/", ResponseNamespace = "http://tempuri.org/", Use = System.Web.Services.Description.SoapBindingUse.Literal, ParameterStyle = System.Web.Services.Protocols.SoapParameterStyle.Wrapped)]
        public void DownloadComplete(string[] pdf_urls)
        {
            this.Invoke("DownloadComplete", new object[] {
                        pdf_urls});
        }

        /// <remarks/>
        public void DownloadCompleteAsync(string[] pdf_urls)
        {
            this.DownloadCompleteAsync(pdf_urls, null);
        }

        /// <remarks/>
        public void DownloadCompleteAsync(string[] pdf_urls, object userState)
        {
            if ((this.DownloadCompleteOperationCompleted == null))
            {
                this.DownloadCompleteOperationCompleted = new System.Threading.SendOrPostCallback(this.OnDownloadCompleteOperationCompleted);
            }
            this.InvokeAsync("DownloadComplete", new object[] {
                        pdf_urls}, this.DownloadCompleteOperationCompleted, userState);
        }

        private void OnDownloadCompleteOperationCompleted(object arg)
        {
            if ((this.DownloadCompleteCompleted != null))
            {
                System.Web.Services.Protocols.InvokeCompletedEventArgs invokeArgs = ((System.Web.Services.Protocols.InvokeCompletedEventArgs)(arg));
                this.DownloadCompleteCompleted(this, new System.ComponentModel.AsyncCompletedEventArgs(invokeArgs.Error, invokeArgs.Cancelled, invokeArgs.UserState));
            }
        }

        /// <remarks/>
        public new void CancelAsync(object userState)
        {
            base.CancelAsync(userState);
        }

        private bool IsLocalFileSystemWebService(string url)
        {
            if (((url == null)
                        || (url == string.Empty)))
            {
                return false;
            }
            System.Uri wsUri = new System.Uri(url);
            if (((wsUri.Port >= 1024)
                        && (string.Compare(wsUri.Host, "localHost", System.StringComparison.OrdinalIgnoreCase) == 0)))
            {
                return true;
            }
            return false;
        }
    }

    /// <remarks/>
    [System.CodeDom.Compiler.GeneratedCodeAttribute("System.Web.Services", "4.0.30319.18408")]
    public delegate void HelloWorldCompletedEventHandler(object sender, HelloWorldCompletedEventArgs e);

    /// <remarks/>
    [System.CodeDom.Compiler.GeneratedCodeAttribute("System.Web.Services", "4.0.30319.18408")]
    [System.Diagnostics.DebuggerStepThroughAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]
    public partial class HelloWorldCompletedEventArgs : System.ComponentModel.AsyncCompletedEventArgs
    {

        private object[] results;

        internal HelloWorldCompletedEventArgs(object[] results, System.Exception exception, bool cancelled, object userState) :
            base(exception, cancelled, userState)
        {
            this.results = results;
        }

        /// <remarks/>
        public string Result
        {
            get
            {
                this.RaiseExceptionIfNecessary();
                return ((string)(this.results[0]));
            }
        }
    }

    /// <remarks/>
    [System.CodeDom.Compiler.GeneratedCodeAttribute("System.Web.Services", "4.0.30319.18408")]
    public delegate void GetPatientIDCompletedEventHandler(object sender, GetPatientIDCompletedEventArgs e);

    /// <remarks/>
    [System.CodeDom.Compiler.GeneratedCodeAttribute("System.Web.Services", "4.0.30319.18408")]
    [System.Diagnostics.DebuggerStepThroughAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]
    public partial class GetPatientIDCompletedEventArgs : System.ComponentModel.AsyncCompletedEventArgs
    {

        private object[] results;

        internal GetPatientIDCompletedEventArgs(object[] results, System.Exception exception, bool cancelled, object userState) :
            base(exception, cancelled, userState)
        {
            this.results = results;
        }

        /// <remarks/>
        public string Result
        {
            get
            {
                this.RaiseExceptionIfNecessary();
                return ((string)(this.results[0]));
            }
        }
    }

    /// <remarks/>
    [System.CodeDom.Compiler.GeneratedCodeAttribute("System.Web.Services", "4.0.30319.18408")]
    public delegate void GetPatientInfoCompletedEventHandler(object sender, GetPatientInfoCompletedEventArgs e);

    /// <remarks/>
    [System.CodeDom.Compiler.GeneratedCodeAttribute("System.Web.Services", "4.0.30319.18408")]
    [System.Diagnostics.DebuggerStepThroughAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]
    public partial class GetPatientInfoCompletedEventArgs : System.ComponentModel.AsyncCompletedEventArgs
    {

        private object[] results;

        internal GetPatientInfoCompletedEventArgs(object[] results, System.Exception exception, bool cancelled, object userState) :
            base(exception, cancelled, userState)
        {
            this.results = results;
        }

        /// <remarks/>
        public bool Result
        {
            get
            {
                this.RaiseExceptionIfNecessary();
                return ((bool)(this.results[0]));
            }
        }

        /// <remarks/>
        public string strPatientID
        {
            get
            {
                this.RaiseExceptionIfNecessary();
                return ((string)(this.results[1]));
            }
        }

        /// <remarks/>
        public string strPatientName
        {
            get
            {
                this.RaiseExceptionIfNecessary();
                return ((string)(this.results[2]));
            }
        }
    }

    /// <remarks/>
    [System.CodeDom.Compiler.GeneratedCodeAttribute("System.Web.Services", "4.0.30319.18408")]
    public delegate void GetReportStatusCompletedEventHandler(object sender, GetReportStatusCompletedEventArgs e);

    /// <remarks/>
    [System.CodeDom.Compiler.GeneratedCodeAttribute("System.Web.Services", "4.0.30319.18408")]
    [System.Diagnostics.DebuggerStepThroughAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]
    public partial class GetReportStatusCompletedEventArgs : System.ComponentModel.AsyncCompletedEventArgs
    {

        private object[] results;

        internal GetReportStatusCompletedEventArgs(object[] results, System.Exception exception, bool cancelled, object userState) :
            base(exception, cancelled, userState)
        {
            this.results = results;
        }

        /// <remarks/>
        public int Result
        {
            get
            {
                this.RaiseExceptionIfNecessary();
                return ((int)(this.results[0]));
            }
        }
    }

    /// <remarks/>
    [System.CodeDom.Compiler.GeneratedCodeAttribute("System.Web.Services", "4.0.30319.18408")]
    public delegate void GetPDFReportListCompletedEventHandler(object sender, GetPDFReportListCompletedEventArgs e);

    /// <remarks/>
    [System.CodeDom.Compiler.GeneratedCodeAttribute("System.Web.Services", "4.0.30319.18408")]
    [System.Diagnostics.DebuggerStepThroughAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]
    public partial class GetPDFReportListCompletedEventArgs : System.ComponentModel.AsyncCompletedEventArgs
    {

        private object[] results;

        internal GetPDFReportListCompletedEventArgs(object[] results, System.Exception exception, bool cancelled, object userState) :
            base(exception, cancelled, userState)
        {
            this.results = results;
        }

        /// <remarks/>
        public string[] Result
        {
            get
            {
                this.RaiseExceptionIfNecessary();
                return ((string[])(this.results[0]));
            }
        }
    }

    /// <remarks/>
    [System.CodeDom.Compiler.GeneratedCodeAttribute("System.Web.Services", "4.0.30319.18408")]
    public delegate void GetPDFListtoPrintCompletedEventHandler(object sender, GetPDFListtoPrintCompletedEventArgs e);

    /// <remarks/>
    [System.CodeDom.Compiler.GeneratedCodeAttribute("System.Web.Services", "4.0.30319.18408")]
    [System.Diagnostics.DebuggerStepThroughAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]
    public partial class GetPDFListtoPrintCompletedEventArgs : System.ComponentModel.AsyncCompletedEventArgs
    {

        private object[] results;

        internal GetPDFListtoPrintCompletedEventArgs(object[] results, System.Exception exception, bool cancelled, object userState) :
            base(exception, cancelled, userState)
        {
            this.results = results;
        }

        /// <remarks/>
        public string[] Result
        {
            get
            {
                this.RaiseExceptionIfNecessary();
                return ((string[])(this.results[0]));
            }
        }
    }

    /// <remarks/>
    [System.CodeDom.Compiler.GeneratedCodeAttribute("System.Web.Services", "4.0.30319.18408")]
    public delegate void DownloadCompleteCompletedEventHandler(object sender, System.ComponentModel.AsyncCompletedEventArgs e);
}

#pragma warning restore 1591