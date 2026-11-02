from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.signup_list_public_status import SignupListPublicStatus

T = TypeVar("T", bound="SignupListPublic")


@_attrs_define
class SignupListPublic:
    """
    Attributes:
        name (str):
        description (None | str):
        status (SignupListPublicStatus):
        min_age_ms (int): How long after this response a submit carrying the nonce is accepted. A client MUST wait it
            out: submitting sooner is rejected as an opaque `400 invalid submission`, and because a retry needs a fresh
            nonce, retrying promptly restarts the same clock indefinitely. Measure the delay from RECEIVING this response,
            not from a clock comparison — the deadline is server-side and client clocks are not trusted.
        nonce (str): Round-trip anti-abuse token, bound to this publicKey. The submit must present it back; it is
            rejected if the signature does not verify, if it was minted for a different list, if it is older than its TTL,
            or if it is younger than the minimum form-fill age. NOT single-use: it is a signed timestamp with no server-side
            record, so the same nonce may be submitted repeatedly until its TTL expires. Clients must not rely on replay
            being refused; the per-IP cap, not the nonce, bounds volume.
    """

    name: str
    description: None | str
    status: SignupListPublicStatus
    min_age_ms: int
    nonce: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        name = self.name

        description: None | str
        description = self.description

        status = self.status.value

        min_age_ms = self.min_age_ms

        nonce = self.nonce

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "name": name,
                "description": description,
                "status": status,
                "minAgeMs": min_age_ms,
                "nonce": nonce,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        name = d.pop("name")

        def _parse_description(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        description = _parse_description(d.pop("description"))

        status = SignupListPublicStatus(d.pop("status"))

        min_age_ms = d.pop("minAgeMs")

        nonce = d.pop("nonce")

        signup_list_public = cls(
            name=name,
            description=description,
            status=status,
            min_age_ms=min_age_ms,
            nonce=nonce,
        )

        signup_list_public.additional_properties = d
        return signup_list_public

    @property
    def additional_keys(self) -> list[str]:
        return list(self.additional_properties.keys())

    def __getitem__(self, key: str) -> Any:
        return self.additional_properties[key]

    def __setitem__(self, key: str, value: Any) -> None:
        self.additional_properties[key] = value

    def __delitem__(self, key: str) -> None:
        del self.additional_properties[key]

    def __contains__(self, key: str) -> bool:
        return key in self.additional_properties
