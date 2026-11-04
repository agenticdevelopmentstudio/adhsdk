from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.integration_test_result_adopted import IntegrationTestResultAdopted


T = TypeVar("T", bound="IntegrationTestResult")


@_attrs_define
class IntegrationTestResult:
    """
    Attributes:
        ok (bool): Whether the provider accepted the credentials. false is an answer.
        summary (str): One line, ready to show an operator — the provider's own refusal when ok is false.
        notes (list[str]): Supporting detail: the accounts reached, the stated non-secret fields the answer was about,
            anything that succeeded partially.
        adopted (IntegrationTestResultAdopted | Unset): GitHub App, saved config only. Testing a GitHub App IS adopting
            its installations — the only proof an app id and private key are real is to mint a JWT and enumerate what the
            app can see, and that enumeration is what creates the connections and warms the repository cache. So this field
            is the connect that just happened, reported.
    """

    ok: bool
    summary: str
    notes: list[str]
    adopted: IntegrationTestResultAdopted | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        ok = self.ok

        summary = self.summary

        notes = self.notes

        adopted: dict[str, Any] | Unset = UNSET
        if not isinstance(self.adopted, Unset):
            adopted = self.adopted.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "ok": ok,
                "summary": summary,
                "notes": notes,
            }
        )
        if adopted is not UNSET:
            field_dict["adopted"] = adopted

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.integration_test_result_adopted import (
            IntegrationTestResultAdopted,
        )

        d = dict(src_dict)
        ok = d.pop("ok")

        summary = d.pop("summary")

        notes = cast(list[str], d.pop("notes"))

        _adopted = d.pop("adopted", UNSET)
        adopted: IntegrationTestResultAdopted | Unset
        if isinstance(_adopted, Unset):
            adopted = UNSET
        else:
            adopted = IntegrationTestResultAdopted.from_dict(_adopted)

        integration_test_result = cls(
            ok=ok,
            summary=summary,
            notes=notes,
            adopted=adopted,
        )

        integration_test_result.additional_properties = d
        return integration_test_result

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
