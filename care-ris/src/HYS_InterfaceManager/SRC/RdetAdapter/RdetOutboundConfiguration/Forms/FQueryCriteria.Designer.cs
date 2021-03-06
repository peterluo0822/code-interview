namespace HYS.RdetAdapter.RdetOutboundAdapterConfiguration.Forms
{
    partial class FQueryCriteria
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.btnOK = new System.Windows.Forms.Button();
            this.btnCancel = new System.Windows.Forms.Button();
            this.groupBox2 = new System.Windows.Forms.GroupBox();
            this.label3 = new System.Windows.Forms.Label();
            this.lblJoin = new System.Windows.Forms.Label();
            this.lblNote = new System.Windows.Forms.Label();
            this.groupBox1 = new System.Windows.Forms.GroupBox();
            this.label4 = new System.Windows.Forms.Label();
            this.label2 = new System.Windows.Forms.Label();
            this.cbValueType = new System.Windows.Forms.ComboBox();
            this.label1 = new System.Windows.Forms.Label();
            this.cmbbxGatewayField = new System.Windows.Forms.ComboBox();
            this.lblFieldType = new System.Windows.Forms.Label();
            this.txtValue = new System.Windows.Forms.TextBox();
            this.lblValue = new System.Windows.Forms.Label();
            this.label7 = new System.Windows.Forms.Label();
            this.label8 = new System.Windows.Forms.Label();
            this.label9 = new System.Windows.Forms.Label();
            this.label10 = new System.Windows.Forms.Label();
            this.enumCmbbxJoin = new EnumComboBox.EnumComboBox();
            this.enumCmbbxOperator = new EnumComboBox.EnumComboBox();
            this.enumCmbbxTable = new EnumComboBox.EnumComboBox();
            this.groupBox2.SuspendLayout();
            this.groupBox1.SuspendLayout();
            this.SuspendLayout();
            // 
            // btnOK
            // 
            this.btnOK.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Right)));
            this.btnOK.Location = new System.Drawing.Point(344, 305);
            this.btnOK.Name = "btnOK";
            this.btnOK.Size = new System.Drawing.Size(55, 22);
            this.btnOK.TabIndex = 4;
            this.btnOK.Text = "OK";
            this.btnOK.UseVisualStyleBackColor = true;
            this.btnOK.Click += new System.EventHandler(this.btnOK_Click);
            // 
            // btnCancel
            // 
            this.btnCancel.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Right)));
            this.btnCancel.Location = new System.Drawing.Point(407, 305);
            this.btnCancel.Name = "btnCancel";
            this.btnCancel.Size = new System.Drawing.Size(55, 22);
            this.btnCancel.TabIndex = 5;
            this.btnCancel.Text = "Cancel";
            this.btnCancel.UseVisualStyleBackColor = true;
            this.btnCancel.Click += new System.EventHandler(this.btnCancel_Click);
            // 
            // groupBox2
            // 
            this.groupBox2.Controls.Add(this.label3);
            this.groupBox2.Controls.Add(this.enumCmbbxJoin);
            this.groupBox2.Controls.Add(this.lblJoin);
            this.groupBox2.Location = new System.Drawing.Point(13, 217);
            this.groupBox2.Name = "groupBox2";
            this.groupBox2.Size = new System.Drawing.Size(449, 72);
            this.groupBox2.TabIndex = 19;
            this.groupBox2.TabStop = false;
            this.groupBox2.Text = "Join Type";
            // 
            // label3
            // 
            this.label3.AutoSize = true;
            this.label3.ForeColor = System.Drawing.Color.Red;
            this.label3.Location = new System.Drawing.Point(134, 32);
            this.label3.Name = "label3";
            this.label3.Size = new System.Drawing.Size(11, 13);
            this.label3.TabIndex = 19;
            this.label3.Text = "*";
            this.label3.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            // 
            // lblJoin
            // 
            this.lblJoin.AutoSize = true;
            this.lblJoin.Location = new System.Drawing.Point(47, 27);
            this.lblJoin.Name = "lblJoin";
            this.lblJoin.Size = new System.Drawing.Size(62, 13);
            this.lblJoin.TabIndex = 17;
            this.lblJoin.Text = "Type Name";
            // 
            // lblNote
            // 
            this.lblNote.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Left)));
            this.lblNote.AutoSize = true;
            this.lblNote.Location = new System.Drawing.Point(16, 305);
            this.lblNote.Name = "lblNote";
            this.lblNote.Size = new System.Drawing.Size(66, 13);
            this.lblNote.TabIndex = 21;
            this.lblNote.Text = "(*: Required)";
            // 
            // groupBox1
            // 
            this.groupBox1.Controls.Add(this.label4);
            this.groupBox1.Controls.Add(this.label2);
            this.groupBox1.Controls.Add(this.cbValueType);
            this.groupBox1.Controls.Add(this.label1);
            this.groupBox1.Controls.Add(this.cmbbxGatewayField);
            this.groupBox1.Controls.Add(this.enumCmbbxOperator);
            this.groupBox1.Controls.Add(this.lblFieldType);
            this.groupBox1.Controls.Add(this.txtValue);
            this.groupBox1.Controls.Add(this.lblValue);
            this.groupBox1.Controls.Add(this.label7);
            this.groupBox1.Controls.Add(this.label8);
            this.groupBox1.Controls.Add(this.enumCmbbxTable);
            this.groupBox1.Controls.Add(this.label9);
            this.groupBox1.Controls.Add(this.label10);
            this.groupBox1.Location = new System.Drawing.Point(13, 5);
            this.groupBox1.Name = "groupBox1";
            this.groupBox1.Size = new System.Drawing.Size(449, 206);
            this.groupBox1.TabIndex = 18;
            this.groupBox1.TabStop = false;
            this.groupBox1.Text = "Data Source";
            this.groupBox1.Enter += new System.EventHandler(this.groupBox1_Enter);
            // 
            // label4
            // 
            this.label4.AutoSize = true;
            this.label4.ForeColor = System.Drawing.Color.Red;
            this.label4.Location = new System.Drawing.Point(133, 122);
            this.label4.Name = "label4";
            this.label4.Size = new System.Drawing.Size(11, 13);
            this.label4.TabIndex = 36;
            this.label4.Text = "*";
            this.label4.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            // 
            // label2
            // 
            this.label2.AutoSize = true;
            this.label2.ForeColor = System.Drawing.Color.Red;
            this.label2.Location = new System.Drawing.Point(133, 95);
            this.label2.Name = "label2";
            this.label2.Size = new System.Drawing.Size(11, 13);
            this.label2.TabIndex = 35;
            this.label2.Text = "*";
            this.label2.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            // 
            // cbValueType
            // 
            this.cbValueType.Enabled = false;
            this.cbValueType.FormattingEnabled = true;
            this.cbValueType.Items.AddRange(new object[] {
            "FixValue"});
            this.cbValueType.Location = new System.Drawing.Point(150, 122);
            this.cbValueType.Name = "cbValueType";
            this.cbValueType.Size = new System.Drawing.Size(264, 21);
            this.cbValueType.TabIndex = 34;
            this.cbValueType.Text = "FixValue";
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.Location = new System.Drawing.Point(47, 124);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(61, 13);
            this.label1.TabIndex = 33;
            this.label1.Text = "Value Type";
            // 
            // cmbbxGatewayField
            // 
            this.cmbbxGatewayField.FormattingEnabled = true;
            this.cmbbxGatewayField.Location = new System.Drawing.Point(150, 61);
            this.cmbbxGatewayField.Name = "cmbbxGatewayField";
            this.cmbbxGatewayField.Size = new System.Drawing.Size(265, 21);
            this.cmbbxGatewayField.TabIndex = 32;
            // 
            // lblFieldType
            // 
            this.lblFieldType.AutoSize = true;
            this.lblFieldType.Location = new System.Drawing.Point(47, 95);
            this.lblFieldType.Name = "lblFieldType";
            this.lblFieldType.Size = new System.Drawing.Size(48, 13);
            this.lblFieldType.TabIndex = 30;
            this.lblFieldType.Text = "Operator";
            // 
            // txtValue
            // 
            this.txtValue.Location = new System.Drawing.Point(150, 153);
            this.txtValue.Name = "txtValue";
            this.txtValue.Size = new System.Drawing.Size(265, 20);
            this.txtValue.TabIndex = 28;
            // 
            // lblValue
            // 
            this.lblValue.AutoSize = true;
            this.lblValue.Location = new System.Drawing.Point(47, 156);
            this.lblValue.Name = "lblValue";
            this.lblValue.Size = new System.Drawing.Size(37, 13);
            this.lblValue.TabIndex = 27;
            this.lblValue.Text = " Value";
            // 
            // label7
            // 
            this.label7.AutoSize = true;
            this.label7.ForeColor = System.Drawing.Color.Red;
            this.label7.Location = new System.Drawing.Point(135, 41);
            this.label7.Name = "label7";
            this.label7.Size = new System.Drawing.Size(11, 13);
            this.label7.TabIndex = 26;
            this.label7.Text = "*";
            this.label7.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            // 
            // label8
            // 
            this.label8.AutoSize = true;
            this.label8.ForeColor = System.Drawing.Color.Red;
            this.label8.Location = new System.Drawing.Point(135, 68);
            this.label8.Name = "label8";
            this.label8.Size = new System.Drawing.Size(11, 13);
            this.label8.TabIndex = 25;
            this.label8.Text = "*";
            this.label8.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            // 
            // label9
            // 
            this.label9.AutoSize = true;
            this.label9.Location = new System.Drawing.Point(48, 35);
            this.label9.Name = "label9";
            this.label9.Size = new System.Drawing.Size(65, 13);
            this.label9.TabIndex = 20;
            this.label9.Text = "Table Name";
            // 
            // label10
            // 
            this.label10.AutoSize = true;
            this.label10.Location = new System.Drawing.Point(48, 67);
            this.label10.Name = "label10";
            this.label10.Size = new System.Drawing.Size(60, 13);
            this.label10.TabIndex = 19;
            this.label10.Text = "Field Name";
            // 
            // enumCmbbxJoin
            // 
            this.enumCmbbxJoin.DropDownStyle = System.Windows.Forms.ComboBoxStyle.DropDownList;
            this.enumCmbbxJoin.FormattingEnabled = true;
            this.enumCmbbxJoin.Items.AddRange(new object[] {
            "None",
            "And",
            "Or"});
            this.enumCmbbxJoin.Location = new System.Drawing.Point(149, 25);
            this.enumCmbbxJoin.Name = "enumCmbbxJoin";
            this.enumCmbbxJoin.Size = new System.Drawing.Size(265, 21);
            this.enumCmbbxJoin.StartIndex = 1;
            this.enumCmbbxJoin.TabIndex = 19;
            this.enumCmbbxJoin.TheType = typeof(HYS.Common.Objects.Rule.QueryCriteriaType);
            // 
            // enumCmbbxOperator
            // 
            this.enumCmbbxOperator.DropDownStyle = System.Windows.Forms.ComboBoxStyle.DropDownList;
            this.enumCmbbxOperator.FormattingEnabled = true;
            this.enumCmbbxOperator.Items.AddRange(new object[] {
            "Equal",
            "NotEqual",
            "LargerThan",
            "EqualLargerThan",
            "SmallerThan",
            "EqualSmallerThan",
            "Like"});
            this.enumCmbbxOperator.Location = new System.Drawing.Point(150, 92);
            this.enumCmbbxOperator.Name = "enumCmbbxOperator";
            this.enumCmbbxOperator.Size = new System.Drawing.Size(264, 21);
            this.enumCmbbxOperator.StartIndex = 0;
            this.enumCmbbxOperator.TabIndex = 31;
            this.enumCmbbxOperator.TheType = typeof(HYS.Common.Objects.Rule.QueryCriteriaOperator);
            // 
            // enumCmbbxTable
            // 
            this.enumCmbbxTable.DropDownStyle = System.Windows.Forms.ComboBoxStyle.DropDownList;
            this.enumCmbbxTable.FormattingEnabled = true;
            this.enumCmbbxTable.Items.AddRange(new object[] {
            "None",
            "Index",
            "Patient",
            "Order",
            "Report"});
            this.enumCmbbxTable.Location = new System.Drawing.Point(151, 32);
            this.enumCmbbxTable.Name = "enumCmbbxTable";
            this.enumCmbbxTable.Size = new System.Drawing.Size(264, 21);
            this.enumCmbbxTable.StartIndex = 0;
            this.enumCmbbxTable.TabIndex = 24;
            this.enumCmbbxTable.TheType = typeof(HYS.Common.Objects.Rule.GWDataDBTable);
            this.enumCmbbxTable.SelectedIndexChanged += new System.EventHandler(this.enumCmbbxTable_SelectedIndexChanged);
            // 
            // FQueryCriteria
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(474, 338);
            this.Controls.Add(this.lblNote);
            this.Controls.Add(this.groupBox2);
            this.Controls.Add(this.groupBox1);
            this.Controls.Add(this.btnCancel);
            this.Controls.Add(this.btnOK);
            this.MaximizeBox = false;
            this.MinimizeBox = false;
            this.Name = "FQueryCriteria";
            this.StartPosition = System.Windows.Forms.FormStartPosition.CenterParent;
            this.groupBox2.ResumeLayout(false);
            this.groupBox2.PerformLayout();
            this.groupBox1.ResumeLayout(false);
            this.groupBox1.PerformLayout();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.Button btnOK;
        private System.Windows.Forms.Button btnCancel;
        private System.Windows.Forms.GroupBox groupBox2;
        private System.Windows.Forms.Label lblJoin;
        private EnumComboBox.EnumComboBox enumCmbbxJoin;
        private System.Windows.Forms.Label label3;
        private System.Windows.Forms.Label lblNote;
        private System.Windows.Forms.GroupBox groupBox1;
        private EnumComboBox.EnumComboBox enumCmbbxOperator;
        private System.Windows.Forms.Label lblFieldType;
        private System.Windows.Forms.TextBox txtValue;
        private System.Windows.Forms.Label lblValue;
        private System.Windows.Forms.Label label7;
        private System.Windows.Forms.Label label8;
        private EnumComboBox.EnumComboBox enumCmbbxTable;
        private System.Windows.Forms.Label label9;
        private System.Windows.Forms.Label label10;
        private System.Windows.Forms.ComboBox cmbbxGatewayField;
        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.ComboBox cbValueType;
        private System.Windows.Forms.Label label4;
        private System.Windows.Forms.Label label2;
    }
}