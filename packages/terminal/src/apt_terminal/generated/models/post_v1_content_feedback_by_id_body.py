from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1ContentFeedbackByIdBody")


@_attrs_define
class PostV1ContentFeedbackByIdBody:
    """
    Attributes:
        ecosystem_id (str | Unset):
        user_email (str | Unset):
        category (str | Unset):
        subject (str | Unset):
        body (str | Unset):
        platform (str | Unset):
        app_version (str | Unset):
        os_version (str | Unset):
        device_info (str | Unset):
        status (str | Unset):
        admin_notes (str | Unset):
    """

    ecosystem_id: str | Unset = UNSET
    user_email: str | Unset = UNSET
    category: str | Unset = UNSET
    subject: str | Unset = UNSET
    body: str | Unset = UNSET
    platform: str | Unset = UNSET
    app_version: str | Unset = UNSET
    os_version: str | Unset = UNSET
    device_info: str | Unset = UNSET
    status: str | Unset = UNSET
    admin_notes: str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        ecosystem_id = self.ecosystem_id

        user_email = self.user_email

        category = self.category

        subject = self.subject

        body = self.body

        platform = self.platform

        app_version = self.app_version

        os_version = self.os_version

        device_info = self.device_info

        status = self.status

        admin_notes = self.admin_notes

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if ecosystem_id is not UNSET:
            field_dict["ecosystem_id"] = ecosystem_id
        if user_email is not UNSET:
            field_dict["user_email"] = user_email
        if category is not UNSET:
            field_dict["category"] = category
        if subject is not UNSET:
            field_dict["subject"] = subject
        if body is not UNSET:
            field_dict["body"] = body
        if platform is not UNSET:
            field_dict["platform"] = platform
        if app_version is not UNSET:
            field_dict["app_version"] = app_version
        if os_version is not UNSET:
            field_dict["os_version"] = os_version
        if device_info is not UNSET:
            field_dict["device_info"] = device_info
        if status is not UNSET:
            field_dict["status"] = status
        if admin_notes is not UNSET:
            field_dict["admin_notes"] = admin_notes

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystem_id", UNSET)

        user_email = d.pop("user_email", UNSET)

        category = d.pop("category", UNSET)

        subject = d.pop("subject", UNSET)

        body = d.pop("body", UNSET)

        platform = d.pop("platform", UNSET)

        app_version = d.pop("app_version", UNSET)

        os_version = d.pop("os_version", UNSET)

        device_info = d.pop("device_info", UNSET)

        status = d.pop("status", UNSET)

        admin_notes = d.pop("admin_notes", UNSET)

        post_v1_content_feedback_by_id_body = cls(
            ecosystem_id=ecosystem_id,
            user_email=user_email,
            category=category,
            subject=subject,
            body=body,
            platform=platform,
            app_version=app_version,
            os_version=os_version,
            device_info=device_info,
            status=status,
            admin_notes=admin_notes,
        )

        return post_v1_content_feedback_by_id_body
