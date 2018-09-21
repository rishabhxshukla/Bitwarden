﻿using AuthenticationServices;
using Bit.iOS.Core.Models;
using Foundation;

namespace Bit.iOS.Autofill.Models
{
    public class Context : AppExtensionContext
    {
        public NSExtensionContext ExtContext { get; set; }
        public ASCredentialServiceIdentifier[] ServiceIdentifiers { get; set; }
    }
}
