from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

T = TypeVar("T", bound="PostCustomerCustomersResponse201")


@_attrs_define
class PostCustomerCustomersResponse201:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        external_id (None | str):
        email (None | str):
        display_name (None | str):
        slug (str):
        avatar_url (str):
        public_profile_enabled (bool):
        profile_visibility (str):
        token_version (int):
        preferred_mfa_method (None | str):
        mfa_failed_attempts (int):
        mfa_locked_until (None | str):
        deleted_at (None | str):
        created_at (str):
        updated_at (str):
        sync_version (int):
        sync_stamped_at (None | str):
        sync_txid (int):
    """

    id: str
    ecosystem_id: str
    external_id: None | str
    email: None | str
    display_name: None | str
    slug: str
    avatar_url: str
    public_profile_enabled: bool
    profile_visibility: str
    token_version: int
    preferred_mfa_method: None | str
    mfa_failed_attempts: int
    mfa_locked_until: None | str
    deleted_at: None | str
    created_at: str
    updated_at: str
    sync_version: int
    sync_stamped_at: None | str
    sync_txid: int

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        external_id: None | str
        external_id = self.external_id

        email: None | str
        email = self.email

        display_name: None | str
        display_name = self.display_name

        slug = self.slug

        avatar_url = self.avatar_url

        public_profile_enabled = self.public_profile_enabled

        profile_visibility = self.profile_visibility

        token_version = self.token_version

        preferred_mfa_method: None | str
        preferred_mfa_method = self.preferred_mfa_method

        mfa_failed_attempts = self.mfa_failed_attempts

        mfa_locked_until: None | str
        mfa_locked_until = self.mfa_locked_until

        deleted_at: None | str
        deleted_at = self.deleted_at

        created_at = self.created_at

        updated_at = self.updated_at

        sync_version = self.sync_version

        sync_stamped_at: None | str
        sync_stamped_at = self.sync_stamped_at

        sync_txid = self.sync_txid

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "ecosystemId": ecosystem_id,
                "externalId": external_id,
                "email": email,
                "displayName": display_name,
                "slug": slug,
                "avatarUrl": avatar_url,
                "publicProfileEnabled": public_profile_enabled,
                "profileVisibility": profile_visibility,
                "tokenVersion": token_version,
                "preferredMfaMethod": preferred_mfa_method,
                "mfaFailedAttempts": mfa_failed_attempts,
                "mfaLockedUntil": mfa_locked_until,
                "deletedAt": deleted_at,
                "createdAt": created_at,
                "updatedAt": updated_at,
                "syncVersion": sync_version,
                "syncStampedAt": sync_stamped_at,
                "syncTxid": sync_txid,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystemId")

        def _parse_external_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        external_id = _parse_external_id(d.pop("externalId"))

        def _parse_email(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        email = _parse_email(d.pop("email"))

        def _parse_display_name(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        display_name = _parse_display_name(d.pop("displayName"))

        slug = d.pop("slug")

        avatar_url = d.pop("avatarUrl")

        public_profile_enabled = d.pop("publicProfileEnabled")

        profile_visibility = d.pop("profileVisibility")

        token_version = d.pop("tokenVersion")

        def _parse_preferred_mfa_method(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        preferred_mfa_method = _parse_preferred_mfa_method(d.pop("preferredMfaMethod"))

        mfa_failed_attempts = d.pop("mfaFailedAttempts")

        def _parse_mfa_locked_until(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        mfa_locked_until = _parse_mfa_locked_until(d.pop("mfaLockedUntil"))

        def _parse_deleted_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        deleted_at = _parse_deleted_at(d.pop("deletedAt"))

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        sync_version = d.pop("syncVersion")

        def _parse_sync_stamped_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        sync_stamped_at = _parse_sync_stamped_at(d.pop("syncStampedAt"))

        sync_txid = d.pop("syncTxid")

        post_customer_customers_response_201 = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            external_id=external_id,
            email=email,
            display_name=display_name,
            slug=slug,
            avatar_url=avatar_url,
            public_profile_enabled=public_profile_enabled,
            profile_visibility=profile_visibility,
            token_version=token_version,
            preferred_mfa_method=preferred_mfa_method,
            mfa_failed_attempts=mfa_failed_attempts,
            mfa_locked_until=mfa_locked_until,
            deleted_at=deleted_at,
            created_at=created_at,
            updated_at=updated_at,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
        )

        return post_customer_customers_response_201
