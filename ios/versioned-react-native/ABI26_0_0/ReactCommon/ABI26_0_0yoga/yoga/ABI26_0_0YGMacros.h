/**
 * Copyright (c) 2014-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#pragma once

#ifdef __cplusplus
#define ABI26_0_0YG_EXTERN_C_BEGIN extern "C" {
#define ABI26_0_0YG_EXTERN_C_END }
#else
#define ABI26_0_0YG_EXTERN_C_BEGIN
#define ABI26_0_0YG_EXTERN_C_END
#endif

#ifdef _WINDLL
#define WIN_EXPORT __declspec(dllexport)
#else
#define WIN_EXPORT
#endif

#ifdef WINARMDLL
#define WIN_STRUCT(type) type *
#define WIN_STRUCT_REF(value) &value
#else
#define WIN_STRUCT(type) type
#define WIN_STRUCT_REF(value) value
#endif

#ifdef NS_ENUM
// Cannot use NSInteger as NSInteger has a different size than int (which is the default type of a
// enum).
// Therefor when linking the Yoga C library into obj-c the header is a missmatch for the Yoga ABI.
#define ABI26_0_0YG_ENUM_BEGIN(name) NS_ENUM(int, name)
#define ABI26_0_0YG_ENUM_END(name)
#else
#define ABI26_0_0YG_ENUM_BEGIN(name) enum name
#define ABI26_0_0YG_ENUM_END(name) name
#endif
